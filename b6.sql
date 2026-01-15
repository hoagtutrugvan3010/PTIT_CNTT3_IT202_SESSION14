create database social_network;
use social_network;

create table friend_requests (
    request_id int primary key auto_increment,
    from_user_id int not null,
    to_user_id int not null,
    status enum('pending','accepted','rejected') default 'pending',
    foreign key (from_user_id) references users(user_id),
    foreign key (to_user_id) references users(user_id)
);

create table friends (
    user_id int not null,
    friend_id int not null,
    primary key (user_id, friend_id),
    foreign key (user_id) references users(user_id),
    foreign key (friend_id) references users(user_id)
);

alter table users add column friends_count int default 0;
delimiter //
create procedure sp_accept_friend_request(
    in p_request_id int,
    in p_to_user_id int
)
begin
    set transaction isolation level repeatable read;
    start transaction;
    -- kiểm tra request tồn tại, pending và đúng người nhận
    if not exists (
        select 1
        from friend_requests
        where request_id = p_request_id
          and to_user_id = p_to_user_id
          and status = 'pending'
    ) then
        rollback;
        signal sqlstate '45000'
        set message_text = 'friend request không hợp lệ';
    end if;
    -- kiểm tra đã là bạn trước đó chưa
    if exists (
        select 1
        from friends f
        join friend_requests fr
            on fr.request_id = p_request_id
        where f.user_id = fr.from_user_id
          and f.friend_id = fr.to_user_id
    ) then
        rollback;
        signal sqlstate '45000'
        set message_text = 'hai user đã là bạn';
    end if;
    -- INSERT vào friends hai bản ghi
    insert into friends(user_id, friend_id)
    select from_user_id, to_user_id from friend_requests
    where request_id = p_request_id;

    insert into friends(user_id, friend_id)
    select to_user_id, from_user_id from friend_requests
    where request_id = p_request_id;
    -- UPDATE tăng friends_count +1 cho cả hai user
    update users
    set friends_count = friends_count + 1
    where user_id = v_from_user;

    update users
    set friends_count = friends_count + 1
    where user_id = v_to_user;
    -- UPDATE friend_requests SET status='accepted'
    update friend_requests
    set status = 'accepted'
    where request_id = p_request_id;

    commit;
end//
delimiter ;
-- user 1 gửi lời mời kết bạn cho user 2
insert into friend_requests(from_user_id, to_user_id) values (1, 2);
-- Gọi procedure và kiểm tra với các tình huống
call sp_accept_friend_request(1, 2);

select * from friends;
select user_id, friends_count from users;
select * from friend_requests;

call sp_accept_friend_request(1, 3);
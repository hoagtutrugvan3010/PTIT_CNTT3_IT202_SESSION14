create database social_network;
use social_network;

create table delete_log (
    log_id int primary key auto_increment,
    post_id int,
    deleted_by int,
    deleted_at datetime default current_timestamp
);

delimiter //
create procedure sp_delete_post(
    in p_post_id int,
    in p_user_id int
)
begin
    start transaction;
    -- kiểm tra bài viết tồn tại và thuộc về user
    if not exists (
        select 1
        from posts
        where post_id = p_post_id
          and user_id = p_user_id
    ) then
        rollback;
        signal sqlstate '45000'
        set message_text = 'bài viết không tồn tại hoặc không có quyền xóa';
    end if;
    -- xóa comment 
    delete from comments
    where post_id = p_post_id;
    -- xóa like
    delete from likes
    where post_id = p_post_id;
    -- xóa bài viết
    delete from posts
    where post_id = p_post_id;
    -- cập nhật số bài viết
    update users
    set posts_count = posts_count - 1
    where user_id = p_user_id;
    -- Nếu mọi bước thành công → COMMIT
    insert into delete_log(post_id, deleted_by)
    values (p_post_id, p_user_id);
    commit;
end//
delimiter ;
-- Gọi procedure với trường hợp hợp lệ
call sp_delete_post(1, 1);
-- Gọi procedure với trường hợp không hợp lệ
 call sp_delete_post(2, 999);
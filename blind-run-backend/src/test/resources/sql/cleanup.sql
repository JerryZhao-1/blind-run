-- 每个测试方法执行前清空数据，保证测试隔离
SET REFERENTIAL_INTEGRITY FALSE;
DELETE FROM order_review;
DELETE FROM run_order;
DELETE FROM volunteer_available_time;
DELETE FROM volunteer_location;
DELETE FROM volunteer_profile;
DELETE FROM blind_profile;
DELETE FROM users;
SET REFERENTIAL_INTEGRITY TRUE;

package com.example.demo.repository;

import com.example.demo.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 用户数据访问层（Repository）—— 负责和数据库交互
 *
 * 【什么是 Repository？】
 * Repository 是 "仓库" 的意思。你可以把它理解为数据库操作的 "遥控器"。
 * 你不需要写 SQL 语句，Spring Data JPA 会根据方法名自动生成 SQL。
 *
 * 【继承了 JpaRepository<User, Long> 是什么意思？】
 * - User：这个仓库管理的是 User 实体
 * - Long：User 的主键类型是 Long
 * 继承之后，自动拥有了增删改查的方法：
 *   findAll()    查询所有用户
 *   findById()   根据ID查询
 *   save()       保存（新增或更新）
 *   deleteById() 根据ID删除
 *
 * 【findByPhone 是怎么工作的？】
 * Spring 会根据方法名自动生成 SQL：
 *   "findByPhone" → SELECT * FROM users WHERE phone = ?
 * 你只需要定义方法名，不需要写实现代码！
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * 根据手机号查找用户
     * @param phone 手机号
     * @return Optional<User> —— 可能找到用户，也可能找不到（用 Optional 包装，避免返回 null）
     */
    Optional<User> findByPhone(String phone);
}

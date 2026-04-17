package com.example.demo.exception;

/**
 * 角色已设定异常 —— 用户尝试修改已设定的角色时抛出
 */
public class RoleAlreadySetException extends RuntimeException {

    public RoleAlreadySetException(String message) {
        super(message);
    }
}

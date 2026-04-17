package com.example.demo.util;

/**
 * 手机号脱敏工具类
 * 保留前3位和后4位，中间替换为 ****
 * 例：138****0001
 */
public class PhoneMaskUtils {

    public static String mask(String phone) {
        if (phone == null || phone.length() < 7) return phone;
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }
}

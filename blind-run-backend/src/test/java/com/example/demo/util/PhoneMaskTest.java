package com.example.demo.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 手机号脱敏单元测试（TC-MASK-01 ~ 02）
 * 纯单元测试，不需要 Spring 容器
 */
class PhoneMaskTest {

    /** TC-MASK-01：标准手机号脱敏 */
    @Test
    @DisplayName("TC-MASK-01: 标准手机号脱敏")
    void tc01_maskNormalPhone() {
        assertEquals("138****0001", PhoneMaskUtils.mask("13800000001"));
        assertEquals("139****5678", PhoneMaskUtils.mask("13900005678"));
        assertEquals("186****1234", PhoneMaskUtils.mask("18612341234"));
    }

    /** TC-MASK-02：边界情况 */
    @Test
    @DisplayName("TC-MASK-02: 边界情况")
    void tc02_maskEdgeCases() {
        assertNull(PhoneMaskUtils.mask(null));
        assertEquals("", PhoneMaskUtils.mask(""));
        // 短号码：不足11位，按实现逻辑处理
        assertNotNull(PhoneMaskUtils.mask("123456"));
    }
}

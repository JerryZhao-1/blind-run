package com.example.demo.integration;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 盲人资料模块集成测试（TC-BLIND-01 ~ 05）
 */
class BlindProfileTest extends BaseIntegrationTest {

    // ==================== 获取资料 ====================

    /** TC-BLIND-01：获取空白资料（设置 BLIND 角色后），所有字段为 null */
    @Test
    @DisplayName("TC-BLIND-01: 获取空白资料")
    void tc01_getEmptyProfile() {
        String token = testHelper.registerAndLoginWithRole("13800030001", "BLIND");

        ResponseEntity<String> response = testHelper.getBlindProfile(token);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("name").isNull()).isTrue();
        assertThat(json.get("emergencyContactName").isNull()).isTrue();
        assertThat(json.get("emergencyContactPhone").isNull()).isTrue();
        assertThat(json.get("emergencyContactRelation").isNull()).isTrue();
        assertThat(json.get("runningPace").isNull()).isTrue();
        assertThat(json.get("specialNeeds").isNull()).isTrue();

        System.out.println("✅ TC-BLIND-01 passed — 获取空白资料");
    }

    // ==================== 更新资料 ====================

    /** TC-BLIND-02：更新全部字段成功 */
    @Test
    @DisplayName("TC-BLIND-02: 更新全部字段成功")
    void tc02_updateProfileAllFields() {
        String token = testHelper.registerAndLoginWithRole("13800030002", "BLIND");

        String updateBody = """
                {
                  "name": "张三",
                  "emergencyContactName": "李四",
                  "emergencyContactPhone": "13900001111",
                  "emergencyContactRelation": "朋友",
                  "runningPace": "6:00",
                  "specialNeeds": "需要语音引导"
                }
                """;

        ResponseEntity<String> response = testHelper.updateBlindProfile(token, updateBody);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();

        // 验证 data 字段
        JsonNode data = json.get("data");
        assertThat(data).isNotNull();
        assertThat(data.get("name").asText()).isEqualTo("张三");
        assertThat(data.get("emergencyContactName").asText()).isEqualTo("李四");
        assertThat(data.get("emergencyContactPhone").asText()).isEqualTo("13900001111");
        assertThat(data.get("emergencyContactRelation").asText()).isEqualTo("朋友");
        assertThat(data.get("runningPace").asText()).isEqualTo("6:00");
        assertThat(data.get("specialNeeds").asText()).isEqualTo("需要语音引导");

        System.out.println("✅ TC-BLIND-02 passed — 更新全部字段成功");
    }

    /** TC-BLIND-03：更新后重新获取，字段匹配（紧急电话对盲人可见明文） */
    @Test
    @DisplayName("TC-BLIND-03: 更新后重新获取资料")
    void tc03_getProfileAfterUpdate() {
        String token = testHelper.registerAndLoginWithRole("13800030003", "BLIND");

        String updateBody = """
                {
                  "name": "王五",
                  "emergencyContactName": "赵六",
                  "emergencyContactPhone": "13900002222",
                  "emergencyContactRelation": "配偶",
                  "runningPace": "5:30",
                  "specialNeeds": "视障一级，需陪跑绳"
                }
                """;

        ResponseEntity<String> updateResp = testHelper.updateBlindProfile(token, updateBody);
        assertThat(updateResp.getStatusCode()).isEqualTo(HttpStatus.OK);

        // 重新获取资料
        ResponseEntity<String> response = testHelper.getBlindProfile(token);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("name").asText()).isEqualTo("王五");
        assertThat(json.get("emergencyContactName").asText()).isEqualTo("赵六");
        // 紧急联系电话对盲人用户显示完整号码（不脱敏）
        assertThat(json.get("emergencyContactPhone").asText()).isEqualTo("13900002222");
        assertThat(json.get("emergencyContactRelation").asText()).isEqualTo("配偶");
        assertThat(json.get("runningPace").asText()).isEqualTo("5:30");
        assertThat(json.get("specialNeeds").asText()).isEqualTo("视障一级，需陪跑绳");

        System.out.println("✅ TC-BLIND-03 passed — 更新后重新获取资料");
    }

    // ==================== 权限控制 ====================

    /** TC-BLIND-04：志愿者无法访问盲人资料，返回 403 */
    @Test
    @DisplayName("TC-BLIND-04: 志愿者无法访问盲人资料")
    void tc04_volunteerCannotAccessBlindProfile() {
        String token = testHelper.registerAndLoginWithRole("13800030004", "VOLUNTEER");

        ResponseEntity<String> response = testHelper.getBlindProfile(token);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);

        System.out.println("✅ TC-BLIND-04 passed — 志愿者无法访问盲人资料");
    }

    /** TC-BLIND-05：未设置角色用户无法访问盲人资料，返回 403 */
    @Test
    @DisplayName("TC-BLIND-05: 未设置角色用户无法访问盲人资料")
    void tc05_unsetUserCannotAccessBlindProfile() {
        // 仅注册，不设置角色（角色为 UNSET）
        String token = testHelper.registerAndLogin("13800030005");

        ResponseEntity<String> response = testHelper.getBlindProfile(token);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);

        System.out.println("✅ TC-BLIND-05 passed — 未设置角色用户无法访问盲人资料");
    }
}

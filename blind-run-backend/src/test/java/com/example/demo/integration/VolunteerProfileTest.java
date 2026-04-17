package com.example.demo.integration;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 志愿者资料模块集成测试（TC-VOL-01 ~ 11）
 */
class VolunteerProfileTest extends BaseIntegrationTest {

    // ==================== 志愿者资料 ====================

    /** TC-VOL-01：设置志愿者角色后获取空资料 */
    @Test
    @DisplayName("TC-VOL-01: 获取空志愿者资料")
    void tc01_getEmptyProfile() {
        String token = testHelper.registerVolunteerWithoutVerification("13800040001");

        ResponseEntity<String> response = testHelper.getVolunteerProfile(token);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("name").isNull()).isTrue();
        assertThat(json.get("verificationStatus").asText()).isEqualTo("NONE");
        assertThat(json.get("availableTimeSlots").isEmpty()).isTrue();

        System.out.println("✅ TC-VOL-01 passed — 获取空志愿者资料");
    }

    /** TC-VOL-02：更新资料（姓名 + 2个时间段） */
    @Test
    @DisplayName("TC-VOL-02: 更新志愿者资料")
    void tc02_updateProfile() {
        String token = testHelper.registerAndLoginWithRole("13800040002", "VOLUNTEER");

        String body = """
                {
                  "name": "张志愿者",
                  "availableTimeSlots": [
                    {"dayOfWeek":"MONDAY","startTime":"09:00","endTime":"11:00"},
                    {"dayOfWeek":"WEDNESDAY","startTime":"14:00","endTime":"16:00"}
                  ]
                }
                """;
        ResponseEntity<String> response = testHelper.updateVolunteerProfile(token, body);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();

        JsonNode data = json.get("data");
        assertThat(data.get("name").asText()).isEqualTo("张志愿者");
        assertThat(data.get("availableTimeSlots").size()).isEqualTo(2);

        System.out.println("✅ TC-VOL-02 passed — 更新志愿者资料");
    }

    /** TC-VOL-03：更新资料时替换而非追加时间段 */
    @Test
    @DisplayName("TC-VOL-03: 时间段替换而非追加")
    void tc03_timeSlotsReplacement() {
        String token = testHelper.registerAndLoginWithRole("13800040003", "VOLUNTEER");

        // 先设置2个时间段
        String body1 = """
                {
                  "name": "李志愿者",
                  "availableTimeSlots": [
                    {"dayOfWeek":"MONDAY","startTime":"09:00","endTime":"11:00"},
                    {"dayOfWeek":"WEDNESDAY","startTime":"14:00","endTime":"16:00"}
                  ]
                }
                """;
        testHelper.updateVolunteerProfile(token, body1);

        // 再更新为1个不同的时间段
        String body2 = """
                {
                  "name": "李志愿者",
                  "availableTimeSlots": [
                    {"dayOfWeek":"FRIDAY","startTime":"10:00","endTime":"12:00"}
                  ]
                }
                """;
        ResponseEntity<String> response = testHelper.updateVolunteerProfile(token, body2);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        // 通过 GET 验证只有新时间段
        ResponseEntity<String> getResp = testHelper.getVolunteerProfile(token);
        assertThat(getResp.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode profile = testHelper.extractJson(getResp.getBody());
        JsonNode slots = profile.get("availableTimeSlots");
        assertThat(slots.size()).isEqualTo(1);
        assertThat(slots.get(0).get("dayOfWeek").asText()).isEqualTo("FRIDAY");

        System.out.println("✅ TC-VOL-03 passed — 时间段替换而非追加");
    }

    /** TC-VOL-04：盲人用户无法访问志愿者资料 */
    @Test
    @DisplayName("TC-VOL-04: 盲人用户无权访问志愿者资料")
    void tc04_blindCannotAccessVolunteerProfile() {
        String token = testHelper.registerAndLoginWithRole("13800040004", "BLIND");

        ResponseEntity<String> response = testHelper.getVolunteerProfile(token);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isFalse();
        assertThat(json.get("code").asInt()).isEqualTo(403);

        System.out.println("✅ TC-VOL-04 passed — 盲人用户无权访问志愿者资料");
    }

    // ==================== 志愿者认证 ====================

    /** TC-VOL-05：上传资质证件 */
    @Test
    @DisplayName("TC-VOL-05: 上传资质证件")
    void tc05_submitVerification() {
        String token = testHelper.registerVolunteerWithoutVerification("13800040005");

        ResponseEntity<String> response = testHelper.submitVerification(token, new byte[]{1, 2, 3}, "test.jpg");
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();
        assertThat(json.get("status").asText()).isEqualTo("APPROVED");

        System.out.println("✅ TC-VOL-05 passed — 上传资质证件");
    }

    /** TC-VOL-06：上传前认证状态为 NONE */
    @Test
    @DisplayName("TC-VOL-06: 上传前认证状态为NONE")
    void tc06_verificationStatusBeforeUpload() {
        String token = testHelper.registerVolunteerWithoutVerification("13800040006");

        ResponseEntity<String> response = testHelper.getVerificationStatus(token);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("status").asText()).isEqualTo("NONE");

        System.out.println("✅ TC-VOL-06 passed — 上传前认证状态为NONE");
    }

    /** TC-VOL-07：上传后认证状态为 APPROVED */
    @Test
    @DisplayName("TC-VOL-07: 上传后认证状态为APPROVED")
    void tc07_verificationStatusAfterUpload() {
        String token = testHelper.registerVolunteerWithoutVerification("13800040007");

        // 先上传
        testHelper.submitVerification(token, new byte[]{1, 2, 3}, "test.jpg");

        // 再查询状态
        ResponseEntity<String> response = testHelper.getVerificationStatus(token);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("status").asText()).isEqualTo("APPROVED");

        System.out.println("✅ TC-VOL-07 passed — 上传后认证状态为APPROVED");
    }

    // ==================== 位置上报 ====================

    /** TC-VOL-08：在线上报位置 */
    @Test
    @DisplayName("TC-VOL-08: 在线上报位置")
    void tc08_updateLocationOnline() {
        String token = testHelper.registerAndLoginWithRole("13800040008", "VOLUNTEER");

        testHelper.updateVolunteerLocation(token, 39.9042, 116.4074, true);

        System.out.println("✅ TC-VOL-08 passed — 在线上报位置");
    }

    /** TC-VOL-09：离线上报位置 */
    @Test
    @DisplayName("TC-VOL-09: 离线上报位置")
    void tc09_updateLocationOffline() {
        String token = testHelper.registerAndLoginWithRole("13800040009", "VOLUNTEER");

        String body = "{\"latitude\":39.9042,\"longitude\":116.4074,\"isOnline\":false}";
        ResponseEntity<String> response = testHelper.updateVolunteerLocationRaw(token, body);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();

        System.out.println("✅ TC-VOL-09 passed — 离线上报位置");
    }

    /** TC-VOL-10：纬度超出范围（200）返回 400 */
    @Test
    @DisplayName("TC-VOL-10: 纬度超出范围返回400")
    void tc10_latitudeOutOfRange() {
        String token = testHelper.registerAndLoginWithRole("13800040010", "VOLUNTEER");

        String body = "{\"latitude\":200,\"longitude\":116.4074,\"isOnline\":true}";
        ResponseEntity<String> response = testHelper.updateVolunteerLocationRaw(token, body);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        System.out.println("✅ TC-VOL-10 passed — 纬度超出范围返回400");
    }

    /** TC-VOL-11：缺少纬度（null）返回 400 */
    @Test
    @DisplayName("TC-VOL-11: 缺少纬度返回400")
    void tc11_missingLatitude() {
        String token = testHelper.registerAndLoginWithRole("13800040011", "VOLUNTEER");

        String body = "{\"longitude\":116.4074,\"isOnline\":true}";
        ResponseEntity<String> response = testHelper.updateVolunteerLocationRaw(token, body);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        System.out.println("✅ TC-VOL-11 passed — 缺少纬度返回400");
    }
}

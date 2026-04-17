package com.example.demo.integration;

import com.example.demo.entity.OrderStatus;
import com.example.demo.entity.VolunteerProfile;
import com.example.demo.repository.VolunteerProfileRepository;
import com.example.demo.service.VerificationCodeService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 测试辅助工具 —— 封装重复的 HTTP 调用，简化测试代码
 */
public class TestHelper {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    private final TestRestTemplate rest;
    private final VerificationCodeService verificationCodeService;
    private final VolunteerProfileRepository volunteerProfileRepository;

    public TestHelper(TestRestTemplate restTemplate, VerificationCodeService verificationCodeService,
                      VolunteerProfileRepository volunteerProfileRepository) {
        this.rest = restTemplate;
        this.verificationCodeService = verificationCodeService;
        this.volunteerProfileRepository = volunteerProfileRepository;
    }

    // ==================== 认证相关 ====================

    /** 发送验证码，返回原始响应 */
    public ResponseEntity<String> sendCode(String phone) {
        return rest.postForEntity("/api/auth/send-code",
                jsonEntity(null, "{\"phone\":\"" + phone + "\"}"), String.class);
    }

    /** 验证码登录，返回原始响应（不断言成功） */
    public ResponseEntity<String> verifyCodeRaw(String phone, String code) {
        return rest.postForEntity("/api/auth/verify-code",
                jsonEntity(null, "{\"phone\":\"" + phone + "\",\"code\":\"" + code + "\"}"), String.class);
    }

    /**
     * 注册并登录，返回 JWT token
     * 直接调用 VerificationCodeService 生成验证码，绕过 send-code HTTP 接口
     */
    public String registerAndLogin(String phone) {
        String code = verificationCodeService.generateAndStoreCode(phone);
        ResponseEntity<String> response = verifyCodeRaw(phone, code);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        return extractToken(response.getBody());
    }

    /** 设置用户角色 */
    public void setRole(String token, String role) {
        ResponseEntity<String> response = rest.postForEntity(
                "/api/user/role", jsonEntity(token, "{\"role\":\"" + role + "\"}"), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    /** 注册 + 设角色，一步到位（志愿者自动认证） */
    public String registerAndLoginWithRole(String phone, String role) {
        String token = registerAndLogin(phone);
        setRole(token, role);

        if ("VOLUNTEER".equals(role)) {
            Long userId = extractUserId(token);
            volunteerProfileRepository.findByUserId(userId).ifPresent(profile -> {
                profile.setVerified(true);
                profile.setVerificationStatus(com.example.demo.entity.VerificationStatus.APPROVED);
                volunteerProfileRepository.save(profile);
            });
        }

        return token;
    }

    /** 注册志愿者但不自动认证 */
    public String registerVolunteerWithoutVerification(String phone) {
        String token = registerAndLogin(phone);
        setRole(token, "VOLUNTEER");
        return token;
    }

    /** 从 JWT token 中解析 userId（通过 /api/auth/me） */
    public Long extractUserId(String token) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + token);
            ResponseEntity<String> resp = rest.exchange(
                    "/api/auth/me", HttpMethod.GET, new HttpEntity<>(headers), String.class);
            JsonNode json = MAPPER.readTree(resp.getBody());
            return json.get("userId").asLong();
        } catch (Exception e) {
            throw new RuntimeException("无法获取 userId: " + e.getMessage(), e);
        }
    }

    /** 获取当前用户信息 */
    public ResponseEntity<String> getMe(String token) {
        return rest.exchange("/api/auth/me", HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    // ==================== 盲人资料 ====================

    public ResponseEntity<String> getBlindProfile(String token) {
        return rest.exchange("/api/blind/profile", HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    public ResponseEntity<String> updateBlindProfile(String token, String body) {
        return rest.exchange("/api/blind/profile", HttpMethod.PUT,
                jsonEntity(token, body), String.class);
    }

    // ==================== 志愿者相关 ====================

    public ResponseEntity<String> getVolunteerProfile(String token) {
        return rest.exchange("/api/volunteer/profile", HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    public ResponseEntity<String> updateVolunteerProfile(String token, String body) {
        return rest.exchange("/api/volunteer/profile", HttpMethod.PUT,
                jsonEntity(token, body), String.class);
    }

    /** 上传资质证件（multipart） */
    public ResponseEntity<String> submitVerification(String token, byte[] content, String filename) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);
        if (token != null) headers.set("Authorization", "Bearer " + token);

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("file", new ByteArrayResource(content) {
            @Override public String getFilename() { return filename; }
        });

        return rest.postForEntity("/api/volunteer/verification",
                new HttpEntity<>(body, headers), String.class);
    }

    public ResponseEntity<String> getVerificationStatus(String token) {
        return rest.exchange("/api/volunteer/verification/status", HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    /** 志愿者上报位置 */
    public void updateVolunteerLocation(String token, double lat, double lng, boolean isOnline) {
        String body = "{\"latitude\":" + lat + ",\"longitude\":" + lng + ",\"isOnline\":" + isOnline + "}";
        ResponseEntity<String> response = rest.postForEntity(
                "/api/volunteer/location", jsonEntity(token, body), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    /** 上报位置，返回原始响应（不断言成功） */
    public ResponseEntity<String> updateVolunteerLocationRaw(String token, String body) {
        return rest.postForEntity("/api/volunteer/location", jsonEntity(token, body), String.class);
    }

    // ==================== 订单相关 ====================

    /** 盲人创建订单，返回 orderId */
    public Long createOrder(String token, double lat, double lng, String address,
                            LocalDateTime plannedStart, LocalDateTime plannedEnd) {
        String body = """
                {
                  "startLatitude": %s,
                  "startLongitude": %s,
                  "startAddress": "%s",
                  "plannedStartTime": "%s",
                  "plannedEndTime": "%s"
                }
                """.formatted(lat, lng, address,
                plannedStart.format(FMT), plannedEnd.format(FMT));

        ResponseEntity<String> response = rest.postForEntity(
                "/api/orders", jsonEntity(token, body), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        return extractJson(response.getBody()).get("id").asLong();
    }

    /** 志愿者接单 */
    public void acceptOrder(String token, Long orderId) {
        ResponseEntity<String> response = rest.postForEntity(
                "/api/orders/" + orderId + "/accept", jsonEntity(token, null), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    /** 接单，返回原始响应 */
    public ResponseEntity<String> acceptOrderRaw(String token, Long orderId) {
        return rest.postForEntity("/api/orders/" + orderId + "/accept",
                jsonEntity(token, null), String.class);
    }

    /** 志愿者拒单 */
    public void rejectOrder(String token, Long orderId) {
        ResponseEntity<String> response = rest.postForEntity(
                "/api/orders/" + orderId + "/reject", jsonEntity(token, null), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    /** 志愿者结束服务 */
    public void finishOrder(String token, Long orderId) {
        ResponseEntity<String> response = rest.postForEntity(
                "/api/orders/" + orderId + "/finish", jsonEntity(token, null), String.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }

    /** 取消订单，返回原始响应 */
    public ResponseEntity<String> cancelOrder(String token, Long orderId) {
        return rest.postForEntity(
                "/api/orders/" + orderId + "/cancel", jsonEntity(token, null), String.class);
    }

    /** 创建订单（不创建，只返回响应），用于断言错误 */
    public ResponseEntity<String> createOrderRaw(String token, String body) {
        return rest.postForEntity("/api/orders", jsonEntity(token, body), String.class);
    }

    /** 查询订单详情，返回完整响应 */
    public ResponseEntity<String> getOrder(String token, Long orderId) {
        HttpHeaders headers = new HttpHeaders();
        if (token != null) headers.set("Authorization", "Bearer " + token);
        return rest.exchange("/api/orders/" + orderId, HttpMethod.GET,
                new HttpEntity<>(headers), String.class);
    }

    /** 查询附近可接订单 */
    public ResponseEntity<String> getAvailableOrders(String token) {
        return rest.exchange("/api/orders/available", HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    /** 查询我的订单 */
    public ResponseEntity<String> getMyOrders(String token, String role, String status, int page, int size) {
        String url = "/api/orders/mine?role=" + role + "&page=" + page + "&size=" + size;
        if (status != null) url += "&status=" + status;
        return rest.exchange(url, HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    /** 获取订单状态 */
    public OrderStatus getOrderStatus(String token, Long orderId) {
        ResponseEntity<String> response = getOrder(token, orderId);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        return OrderStatus.valueOf(extractJson(response.getBody()).get("status").asText());
    }

    /** 轮询等待订单状态变更（异步匹配需要等待） */
    public void waitForOrderStatus(String token, Long orderId,
                                   OrderStatus expected, int timeoutSeconds) throws InterruptedException {
        long deadline = System.currentTimeMillis() + timeoutSeconds * 1000L;
        while (System.currentTimeMillis() < deadline) {
            try {
                OrderStatus current = getOrderStatus(token, orderId);
                if (current == expected) return;
            } catch (AssertionError e) {
                // 订单可能还不存在或状态不对，继续等待
            }
            Thread.sleep(200);
        }
        OrderStatus finalStatus = getOrderStatus(token, orderId);
        assertThat(finalStatus)
                .as("订单 %d 应在 %d 秒内变为 %s", orderId, timeoutSeconds, expected)
                .isEqualTo(expected);
    }

    // ==================== 评价相关 ====================

    public ResponseEntity<String> createReview(String token, Long orderId, int rating, String comment) {
        String body;
        if (comment != null) {
            body = "{\"rating\":" + rating + ",\"comment\":\"" + comment + "\"}";
        } else {
            body = "{\"rating\":" + rating + "}";
        }
        return rest.postForEntity("/api/orders/" + orderId + "/review",
                jsonEntity(token, body), String.class);
    }

    public ResponseEntity<String> getReview(String token, Long orderId) {
        return rest.exchange("/api/orders/" + orderId + "/reviews", HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    // ==================== 用户相关 ====================

    public ResponseEntity<String> getUserInfo(String token, Long userId) {
        return rest.exchange("/api/users/" + userId, HttpMethod.GET,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    public ResponseEntity<String> deleteUser(String token, Long userId) {
        return rest.exchange("/api/users/" + userId, HttpMethod.DELETE,
                new HttpEntity<>(authOnlyHeaders(token)), String.class);
    }

    // ==================== 完整流程辅助 ====================

    /** 完成一个完整的订单流程（创建→匹配→接单→完成），返回 FlowResult */
    public FlowResult completeOrderFlow(String blindPhone, String volPhone) throws Exception {
        String blindToken = registerAndLoginWithRole(blindPhone, "BLIND");
        String volToken = registerAndLoginWithRole(volPhone, "VOLUNTEER");

        updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        Long orderId = createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                defaultStartTime(), defaultEndTime());

        waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);
        acceptOrder(volToken, orderId);
        finishOrder(volToken, orderId);

        return new FlowResult(blindToken, volToken, orderId);
    }

    /** 完成订单到 IN_PROGRESS（不含 finish），返回 FlowResult */
    public FlowResult setupOrderInProgress(String blindPhone, String volPhone) throws Exception {
        String blindToken = registerAndLoginWithRole(blindPhone, "BLIND");
        String volToken = registerAndLoginWithRole(volPhone, "VOLUNTEER");

        updateVolunteerLocation(volToken, 39.9242, 116.4677, true);

        Long orderId = createOrder(blindToken, 39.9042, 116.4674, "朝阳公园南门",
                defaultStartTime(), defaultEndTime());

        waitForOrderStatus(blindToken, orderId, OrderStatus.PENDING_ACCEPT, 5);
        acceptOrder(volToken, orderId);

        return new FlowResult(blindToken, volToken, orderId);
    }

    // ==================== 辅助方法 ====================

    /** 创建带 JWT + JSON 的请求实体 */
    public HttpEntity<String> jsonEntity(String token, String body) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        if (token != null) headers.set("Authorization", "Bearer " + token);
        return new HttpEntity<>(body, headers);
    }

    /** 仅带 JWT 的请求头（无 Content-Type） */
    private HttpHeaders authOnlyHeaders(String token) {
        HttpHeaders headers = new HttpHeaders();
        if (token != null) headers.set("Authorization", "Bearer " + token);
        return headers;
    }

    /** 从登录响应中提取 token */
    protected String extractToken(String responseBody) {
        try {
            JsonNode json = MAPPER.readTree(responseBody);
            return json.get("token").asText();
        } catch (Exception e) {
            throw new RuntimeException("无法从响应中提取 token: " + responseBody, e);
        }
    }

    /** 解析 JSON 字符串 */
    public JsonNode extractJson(String json) {
        try {
            return MAPPER.readTree(json);
        } catch (Exception e) {
            throw new RuntimeException("JSON 解析失败: " + json, e);
        }
    }

    /** 默认的订单时间：开始=1小时后，结束=2小时后 */
    public static LocalDateTime defaultStartTime() {
        return LocalDateTime.now().plusHours(1);
    }

    public static LocalDateTime defaultEndTime() {
        return LocalDateTime.now().plusHours(2);
    }

    /** 完整流程结果 */
    public record FlowResult(String blindToken, String volToken, Long orderId) {}
}

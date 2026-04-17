package com.example.demo.integration;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 评价模块集成测试（TC-REVIEW-01 ~ 08）
 */
class ReviewTest extends BaseIntegrationTest {

    /** TC-REVIEW-01：盲人对已完成订单创建评价 → 201 */
    @Test
    @DisplayName("TC-REVIEW-01: 盲人对已完成订单创建评价")
    void tc01_blindReviewCompletedOrder() throws Exception {
        var flow = testHelper.completeOrderFlow("13800090001", "13800090002");

        ResponseEntity<String> response = testHelper.createReview(
                flow.blindToken(), flow.orderId(), 5, "很好");

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();

        System.out.println("✅ TC-REVIEW-01 passed — 盲人对已完成订单创建评价");
    }

    /** TC-REVIEW-02：重复评价 → 409 "已评价" */
    @Test
    @DisplayName("TC-REVIEW-02: 重复评价")
    void tc02_duplicateReview() throws Exception {
        var flow = testHelper.completeOrderFlow("13800090003", "13800090004");

        // 第一次评价成功
        ResponseEntity<String> first = testHelper.createReview(
                flow.blindToken(), flow.orderId(), 5, "很好");
        assertThat(first.getStatusCode()).isEqualTo(HttpStatus.CREATED);

        // 第二次评价应失败
        ResponseEntity<String> second = testHelper.createReview(
                flow.blindToken(), flow.orderId(), 4, "再来一次");
        assertThat(second.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        JsonNode json = testHelper.extractJson(second.getBody());
        assertThat(json.get("message").asText()).contains("已评价");

        System.out.println("✅ TC-REVIEW-02 passed — 重复评价");
    }

    /** TC-REVIEW-03：对未完成的订单评价 → 409 "已完成" */
    @Test
    @DisplayName("TC-REVIEW-03: 对未完成订单评价")
    void tc03_reviewNonCompletedOrder() throws Exception {
        var flow = testHelper.setupOrderInProgress("13800090005", "13800090006");

        ResponseEntity<String> response = testHelper.createReview(
                flow.blindToken(), flow.orderId(), 5, "很好");
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("message").asText()).contains("已完成");

        System.out.println("✅ TC-REVIEW-03 passed — 对未完成订单评价");
    }

    /** TC-REVIEW-04：志愿者不能评价 → 403 */
    @Test
    @DisplayName("TC-REVIEW-04: 志愿者不能评价")
    void tc04_volunteerCannotReview() throws Exception {
        var flow = testHelper.completeOrderFlow("13800090007", "13800090008");

        // 用志愿者的 token 尝试评价
        ResponseEntity<String> response = testHelper.createReview(
                flow.volToken(), flow.orderId(), 5, "志愿者评价");
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);

        System.out.println("✅ TC-REVIEW-04 passed — 志愿者不能评价");
    }

    /** TC-REVIEW-05：评分为 0 → 400 (@Min(1)) */
    @Test
    @DisplayName("TC-REVIEW-05: 评分为0")
    void tc05_ratingZero() throws Exception {
        var flow = testHelper.completeOrderFlow("13800090009", "13800090010");

        // 发送原始 JSON，rating=0，触发 @Min(1) 校验
        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/orders/" + flow.orderId() + "/review",
                testHelper.jsonEntity(flow.blindToken(), "{\"rating\":0}"), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        System.out.println("✅ TC-REVIEW-05 passed — 评分为0");
    }

    /** TC-REVIEW-06：评分为 6 → 400 (@Max(5)) */
    @Test
    @DisplayName("TC-REVIEW-06: 评分为6")
    void tc06_ratingSix() throws Exception {
        var flow = testHelper.completeOrderFlow("13800090011", "13800090012");

        // 发送原始 JSON，rating=6，触发 @Max(5) 校验
        ResponseEntity<String> response = restTemplate.postForEntity(
                "/api/orders/" + flow.orderId() + "/review",
                testHelper.jsonEntity(flow.blindToken(), "{\"rating\":6}"), String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        System.out.println("✅ TC-REVIEW-06 passed — 评分为6");
    }

    /** TC-REVIEW-07：评论为 null 允许 → 201 */
    @Test
    @DisplayName("TC-REVIEW-07: 评论为null允许")
    void tc07_nullCommentAllowed() throws Exception {
        var flow = testHelper.completeOrderFlow("13800090013", "13800090014");

        // comment=null，TestHelper.createReview 会省略 comment 字段
        ResponseEntity<String> response = testHelper.createReview(
                flow.blindToken(), flow.orderId(), 4, null);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("success").asBoolean()).isTrue();

        System.out.println("✅ TC-REVIEW-07 passed — 评论为null允许");
    }

    /** TC-REVIEW-08：查询没有评价的订单 → {"data":null} */
    @Test
    @DisplayName("TC-REVIEW-08: 查询没有评价的订单")
    void tc08_getReviewNoReview() throws Exception {
        var flow = testHelper.completeOrderFlow("13800090015", "13800090016");

        // 不评价，直接查询
        ResponseEntity<String> response = testHelper.getReview(flow.blindToken(), flow.orderId());

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        JsonNode json = testHelper.extractJson(response.getBody());
        assertThat(json.get("data").isNull()).isTrue();

        System.out.println("✅ TC-REVIEW-08 passed — 查询没有评价的订单");
    }
}

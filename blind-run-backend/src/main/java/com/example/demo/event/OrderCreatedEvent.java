package com.example.demo.event;

import com.example.demo.entity.RunOrder;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

/**
 * 订单创建事件 —— 订单保存到数据库后发布此事件，触发异步匹配流程
 *
 * 【什么是事件？】
 * 就像现实生活中"发传单"：
 * - OrderService 创建订单后，发布这个事件（相当于发传单）
 * - MatchingService 监听这个事件（相当于收到传单后开始工作）
 *
 * 【为什么要用事件而不是直接调用？】
 * 解耦！OrderService 不需要知道 MatchingService 的存在。
 * 以后如果要加新功能（如发送通知），只需添加新的事件监听器，不需要改 OrderService。
 *
 * 【@Async + @EventListener】
 * 事件监听器标注 @Async 后，会在独立线程中执行，不会阻塞订单创建流程。
 * 用户下单后立即收到 201 响应，匹配在后台异步进行。
 */
@Getter
public class OrderCreatedEvent extends ApplicationEvent {

    private final RunOrder order;

    public OrderCreatedEvent(Object source, RunOrder order) {
        super(source);
        this.order = order;
    }
}

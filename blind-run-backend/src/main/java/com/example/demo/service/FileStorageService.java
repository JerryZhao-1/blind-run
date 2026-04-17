package com.example.demo.service;

import org.springframework.web.multipart.MultipartFile;

/**
 * 文件存储服务接口 —— 预留对接云存储（OSS）的扩展点
 */
public interface FileStorageService {
    /**
     * 存储文件，返回文件路径
     */
    String store(MultipartFile file);
}

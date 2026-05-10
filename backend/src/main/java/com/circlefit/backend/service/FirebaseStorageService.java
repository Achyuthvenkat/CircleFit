package com.circlefit.backend.service;

import com.google.cloud.storage.Blob;
import com.google.cloud.storage.Bucket;
import com.google.firebase.cloud.StorageClient;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Service
public class FirebaseStorageService {

    public String uploadFile(MultipartFile file, String folder) throws IOException {
        Bucket bucket = StorageClient.getInstance().bucket();

        String fileName = folder + "/" + UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
        
        Blob blob = bucket.create(fileName, file.getBytes(), file.getContentType());
        
        // This makes the file publicly readable, or you can just return the storage URL
        // However, to get a long lived URL without signing it every time:
        return "https://firebasestorage.googleapis.com/v0/b/" + bucket.getName() + "/o/" + 
               fileName.replace("/", "%2F") + "?alt=media";
    }
}

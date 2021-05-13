//
//  AWSS3Manager.swift
//
//
//  Created by  on 17/01/20.
//  Copyright © Magic-IOS 2020 . All rights reserved.
//

import UIKit
import AWSS3

enum AWS_FILE_TYPE : Int{
    case image
    case video
    case document
}

typealias progressBlock = (_ progress: Double) -> Void //2
typealias completionBlock = (_ response: Any?, _ error: Error?) -> Void //3

class AWSS3Manager {
    
    static let shared = AWSS3Manager() // 4
    private init () { }
    let bucketName = "" // your bucket name
    
    
    var index = 0
    
    var activeUploads: [AWSUploadTaskModel] = [AWSUploadTaskModel]()
    
    func sequenceUpload()  {
        
        guard index < activeUploads.count else {
            index = 0
            activeUploads.removeAll()
            return
        }

        let task = activeUploads[index]
        index += 1
        
        let msgType =  task.fileType
        
        switch msgType {
        case .image:
            
            let fileName = task.localPath.lastPathComponent
            self.uploadfile(fileUrl: task.localPath, fileName: task.remotePath + fileName, contenType: "image", progress: task.progressCallback, completion: task.completionCallback)
            
        case .video:
            
            let fileName = task.localPath.lastPathComponent
            self.uploadfile(fileUrl: task.localPath, fileName: task.remotePath + fileName, contenType: "video", progress: task.progressCallback, completion: task.completionCallback)
            
        case .document:
            
            let fileName = task.localPath.lastPathComponent
            self.uploadfile(fileUrl: task.localPath, fileName: task.remotePath + fileName, contenType: "pdf", progress: task.progressCallback, completion: task.completionCallback)
            
        default:
            break
        }
        
    }
    
    func CancelAllDownloadAndUploadTask() {
        
        self.activeUploads.removeAll()
        self.index = 0
        
        
        URLSession.shared.getAllTasks { (tasks) in
            //tasks.filter{$0.state == .running}.filter { $0.originalRequest?.url == url }.first?.cancel()
        }
    }

    // Upload video from local path url
    func uploadVideo(videoUrl: URL, progress: progressBlock?, completion: completionBlock?) {
        let fileName = self.getUniqueFileName(fileUrl: videoUrl)
        self.uploadfile(fileUrl: videoUrl, fileName: fileName, contenType: "video", progress: progress, completion: completion)
    }
    
    // Upload auido from local path url
    func uploadAudio(audioUrl: URL, progress: progressBlock?, completion: completionBlock?) {
        let fileName = self.getUniqueFileName(fileUrl: audioUrl)
        self.uploadfile(fileUrl: audioUrl, fileName: fileName, contenType: "audio", progress: progress, completion: completion)
    }
    
    // Upload files like Text, Zip, etc from local path url
    func uploadOtherFile(fileUrl: URL, conentType: String, progress: progressBlock?, completion: completionBlock?) {
        let fileName = self.getUniqueFileName(fileUrl: fileUrl)
        self.uploadfile(fileUrl: fileUrl, fileName: fileName, contenType: conentType, progress: progress, completion: completion)
    }
    
    // Get unique file name
    func getUniqueFileName(fileUrl: URL) -> String {
        let strExt: String = "." + (URL(fileURLWithPath: fileUrl.absoluteString).pathExtension)
        return (ProcessInfo.processInfo.globallyUniqueString + (strExt))
    }
    
    //MARK:- AWS file upload
    // fileUrl :  file local path url
    // fileName : name of file, like "myimage.jpeg" "video.mov"
    // contenType: file MIME type
    // progress: file upload progress, value from 0 to 1, 1 for 100% complete
    // completion: completion block when uplaoding is finish, you will get S3 url of upload file here
    private func uploadfile(fileUrl: URL, fileName: String, contenType: String, progress: progressBlock?, completion: completionBlock?) {
        
        // Upload progress block
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.setValue("public-read", forRequestHeader: "x-amz-acl")
        expression.progressBlock = {(task, awsProgress) in
            guard let uploadProgress = progress else { return }
            DispatchQueue.main.async {
                uploadProgress(awsProgress.fractionCompleted)
            }
        }
        // Completion block
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    if var url = AWSS3.default().configuration.endpoint.url { //URL(string: "Constant.S3BUCKETURL") {//AWSS3.default().configuration.endpoint.url{
                        url.appendPathComponent(self.bucketName)
                        let publicURL = url.appendingPathComponent(fileName)
                        print("Uploaded to:\(String(describing: publicURL))")
                        if let completionBlock = completion {
                            completionBlock(publicURL.absoluteString, nil)
                        }
                    }
                    
                } else {
                    if let completionBlock = completion {
                        completionBlock(nil, error)
                    }
                }
                AWSS3Manager.shared.sequenceUpload()
            })
        }
        // Start uploading using AWSS3TransferUtility
        let awsTransferUtility = AWSS3TransferUtility.default()
        awsTransferUtility.uploadFile(fileUrl, bucket: bucketName, key: fileName, contentType: contenType, expression: expression, completionHandler: completionHandler).continueWith { (task) -> Any? in
            if let error = task.error {
                print("error is: \(error.localizedDescription)")
                if let completionBlock = completion {
                    completionBlock(nil, error)
                }
            }
            if let _ = task.result {
                // your uploadTask
            }
            return nil
        }
    }
}

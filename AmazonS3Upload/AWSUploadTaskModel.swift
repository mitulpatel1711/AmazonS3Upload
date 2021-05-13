//
//  ChatUploadTask.swift
//  
//
//  Created by Magic-IOS on 18/01/20.
//  Copyright © 2020 . All rights reserved.
//

import Foundation
import UIKit

protocol AWSUploadTaskDelegate: class {
    func progress( progress: Double , objAwsModel: AWSUploadTaskModel)
    func UploadCompleted( CompletionData: Any? , error: Error? , objAwsModel: AWSUploadTaskModel)
}

struct Model_UploadMedia {
    let data: Data
    let msgType: AWS_FILE_TYPE
    
    init(msgType: AWS_FILE_TYPE , data: Data) {
        self.msgType = msgType
        self.data = data
    }
}

class AWSUploadTaskModel {

    // MARK: - Variables And Properties
    //
    var isUploading = false
    var progress: Double = 0
    var resumeData: Data?
    var uploaded = false
    var objModel: AnyObject
    var localPath: URL
    var fileType: AWS_FILE_TYPE = .image
    var remotePath : String = ""
    var progressCallback: progressBlock?
    var completionCallback: completionBlock?
    
    weak var delegate: AWSUploadTaskDelegate?
    
    //
    // MARK: - Initialization
    //
    init(objChat: AnyObject , localPath: URL,remotePath : String) {
        self.objModel = objChat
        self.localPath = localPath
        self.remotePath = remotePath
        self.progressCallback = { _progress in
            self.progress = _progress
            self.delegate?.progress(progress: self.progress, objAwsModel: self)
        }
        
        self.completionCallback = { _data,error in
            
            print("============== ChatUploadTask = completionCallback")
            
            if error != nil {
                print("Uploaded Error: \(error?.localizedDescription ?? "")")
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                self.delegate?.UploadCompleted(CompletionData: _data, error: error, objAwsModel: self)
            }
            

        }
        
    }
    
}

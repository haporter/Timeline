//
//  PostController.swift
//  Timeline
//
//  Created by Andrew Porter on 3/19/16.
//  Copyright © 2016 Andrew Porter. All rights reserved.
//

import Foundation
import UIKit

class PostController {
    
    static func fetchTimelineForUser(user: User, completion: (posts: [Post]) -> Void) {
        UserController.followedByUser(user) { (users) in
            
            var allPosts: [Post] = []
            let dispatchGroup = dispatch_group_create()
            
            dispatch_group_enter(dispatchGroup)
            PostController.postsForUser(UserController.sharedController.currentUser, completion: { (posts) in
                
                if let posts = posts {
                    allPosts += posts
                }
                
                dispatch_group_leave(dispatchGroup)
            })
            
            if let users = users {
                for user in users {
                    dispatch_group_enter(dispatchGroup)
                    PostController.postsForUser(user, completion: { (posts) in
                        
                        if let posts = posts {
                            allPosts += posts
                        }
                        dispatch_group_leave(dispatchGroup)
                    })
                }
            }
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), { 
                
                let orderedPosts = PostController.orderPosts(allPosts)
                
                completion(posts: orderedPosts)
            })
        }
        
    }
    
    static func addPost(image: UIImage, caption: String?, completion: (success: Bool, post: Post?) -> Void) {
        
        ImageController.uploadImage(image) { (identifier) in
            
            if let identifier = identifier {
                var post = Post(imageEndPoint: identifier, caption: caption)
                post.save()
                
                completion(success: true, post: post)
            } else {
                completion(success: false, post: nil)
            }
        }
    }
    
    static func postFromIdentifier(identifier: String, completion: (post: Post?) -> Void) {
        
        FirebaseController.dataAtEndpoint("posts/\(identifier)") { (data) -> Void in
            
            if let data = data as? [String: AnyObject] {
                let post = Post(json: data, identifier: identifier)
                
                completion(post: post)
            } else {
                completion(post: nil)
            }
        }
    }
    
    static func postsForUser(user: User, completion: (posts: [Post]?) -> Void) {
        
        let ref = FirebaseController.base.childByAppendingPath("posts")
        
        ref.queryOrderedByChild("username").queryEqualToValue(user.username).observeEventType(.Value, withBlock: { (snapshot) in
            
            if let data = snapshot.value as? [String: AnyObject] {
                let posts = data.flatMap({Post(json: $0.1 as! [String: AnyObject], identifier: $0.0)})
                
                let orderedPosts = orderPosts(posts)
                
                completion(posts: orderedPosts)
            } else {
                completion(posts: nil)
            }
        })
    }
    
    static func deletePost(post: Post) {
        post.delete()
    }
    
    static func addCommentWithTextToPost(commentText: String, post: Post, completion: (success: Bool, post: Post?) -> Void) {
        if let postIdentifier = post.uid {
            var comment = Comment(username: UserController.sharedController.currentUser.username, text: commentText, postID: postIdentifier)
            comment.save()
            
            PostController.postFromIdentifier(postIdentifier, completion: { (post) in
                completion(success: true, post: post)
            })
        } else {
            var post = post
            post.save()
            
            if let postID = post.uid {
                var comment = Comment(username: UserController.sharedController.currentUser.username, text: commentText, postID: postID)
                comment.save()
                
                PostController.postFromIdentifier(postID, completion: { (post) in
                    completion(success: true, post: post)
                })
            }
        }
    }
    
    static func addLikeToPost(post: Post, completion: (success: Bool, post: Post?) -> Void) {
        if let postID = post.uid {
            var like = Like(username: UserController.sharedController.currentUser.username, postID: postID)
            like.save()
            
        } else {
            var post = post
            post.save()
            
            var like = Like(username: UserController.sharedController.currentUser.username, postID: post.uid!)
            like.save()
        }
        PostController.postFromIdentifier(post.uid!) { (post) in
            completion(success: true, post: post)
        }
    }
    
    static func deleteComment(comment: Comment, completion: (success: Bool, post: Post?) -> Void) {
        comment.delete()
        
        PostController.postFromIdentifier(comment.postID) { (post) in
            completion(success: true, post: post)
        }
    }
    
    static func deleteLike(like: Like, completion: (success: Bool, post: Post?) -> Void) {
        like.delete()
        
        PostController.postFromIdentifier(like.postID) { (post) in
            completion(success: true, post: post)
        }
    }
    
    static func orderPosts(posts: [Post]) -> [Post] {
        
        return posts.sort({$0.0.uid > $0.1.uid})
    }
    
    static func mockPosts() -> [Post] {
        
        let like1 = Like(username: "Hyrum", postID: "1234")
        let like2 = Like(username: "Andrew", postID: "2345")
        let like3 = Like(username: "Porter", postID: "3456")
        
        let comment1 = Comment(username: "Libby", text: "cute", postID: "1234")
        let comment2 = Comment(username: "Paul", text: "cool", postID: "2345")
        let comment3 = Comment(username: "Mike", text: "awesome", postID: "3456")
        
        let post1 = Post(imageEndPoint: "-K1l4125TYvKMc7rcp5e", caption: "wow", username: "haporter", comments: [comment1], likes: [like1])
        let post2 = Post(imageEndPoint: "-K1l4125TYvKMc7rcp5e", caption: "noway", username: "haporter", comments: [comment2], likes: [like2])
        let post3 = Post(imageEndPoint: "-K1l4125TYvKMc7rcp5e", caption: "fun", username: "haporter", comments: [comment3], likes: [like3])
        
        return [post1, post2, post3]
    }
}
































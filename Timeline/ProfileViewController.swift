//
//  ProfileViewController.swift
//  Timeline
//
//  Created by Andrew Porter on 11/3/15.
//  Copyright © 2015 Andrew Porter. All rights reserved.
//

import UIKit
import SafariServices

class ProfileViewController: UIViewController, UICollectionViewDataSource, ProfileHeaderCollectionReusableViewDelegate {
    
    var user: User?
    var userPosts: [Post] = []

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if user == nil {
            user = UserController.sharedController.currentUser
            editBarButtonItem.enabled = true
        }
        
        print(user)
        updateBasedOnUser()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UserController.userForIdentifier(user!.identifier!) { (user) -> Void in
            self.user = user
            self.updateBasedOnUser()
        }
    }
    
    func updateBasedOnUser() {
        guard let user = user else { return }
        
        title = user.username
        
        PostController.postsForUser(user) { (posts) -> Void in
            if let posts = posts {
                self.userPosts = posts
            } else {
                self.userPosts = []
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.collectionView.reloadData()
            })
        }
    }
    
    // MARK: - Collection View Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPosts.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCollectionViewCell", forIndexPath: indexPath) as! ImageCollectionViewCell
        
        let post = userPosts[indexPath.item]
        
        cell.updateWithImageIdentifier(post.imageEndpoint)
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", forIndexPath: indexPath) as! ProfileHeaderCollectionReusableView
        
        headerView.updateWithUser(user!)
        headerView.delegate = self
        
        return headerView
    }
    

    // MARK: - Profile Header Collection View Delegate
    
    func userTappedURLButton() {
        if let profileURL = NSURL(string: user!.url!) {
            let safariViewController = SFSafariViewController(URL: profileURL)
            
            presentViewController(safariViewController, animated: true, completion: nil)
        }
    }
    
    func userTappedfollowActionButton() {
        guard let user = user else { return }
        
        if user == UserController.sharedController.currentUser {
            
            UserController.logOutCurrentUser()
            tabBarController?.selectedViewController = tabBarController?.viewControllers![0]
            
        } else {
            UserController.userFollowsUser(UserController.sharedController.currentUser, userCheck: user, completion: { (follows) -> Void in
                
                if follows {
                    UserController.unfollowUser(self.user!, completion: { (success) -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.updateBasedOnUser()
                        })
                    })
                } else {
                    UserController.followUser(self.user!, completion: { (success) -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.updateBasedOnUser()
                        })
                    })
                }
            })
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toEditProfile" {
            let destinationViewController = segue.destinationViewController as? LoginSignupViewController
            
            _ = destinationViewController?.view
            
            destinationViewController?.updateWithUser(user!)
        } else if segue.identifier == "profileToPostDetail" {
            if let cell = sender as? UICollectionViewCell, let indexPath = collectionView.indexPathForCell(cell) {
                
                let post = userPosts[indexPath.row]
                
                let destinationViewController = segue.destinationViewController as? PostDetailTableViewController
                
                destinationViewController?.post = post
            }
        }
    }
    
    

}













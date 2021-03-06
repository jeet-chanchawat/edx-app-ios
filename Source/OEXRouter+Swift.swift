//
//  OEXRouter+Swift.swift
//  edX
//
//  Created by Akiva Leffert on 5/7/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

// The router is an indirection point for navigation throw our app.

// New router logic should live here so it can be written in Swift.
// We should gradually migrate the existing router class here and then
// get rid of the objc version

enum CourseHTMLBlockSubkind {
    case Base
    case Problem
}

enum CourseBlockDisplayType {
    case Unknown
    case Outline
    case Unit
    case Video
    case HTML(CourseHTMLBlockSubkind)
    case Discussion(DiscussionModel)
    
    var isUnknown : Bool {
        switch self {
        case Unknown: return true
        default: return false
        }
    }
}

extension CourseBlock {
    
    var displayType : CourseBlockDisplayType {
        switch self.type {
        case .Unknown(_), .HTML: return multiDevice ? .HTML(.Base) : .Unknown
        case .Problem: return multiDevice ? .HTML(.Problem) : .Unknown
        case .Course: return .Outline
        case .Chapter: return .Outline
        case .Section: return .Outline
        case .Unit: return .Unit
        case let .Video(summary): return (summary.isSupportedVideo) ? .Video : .Unknown
        case let .Discussion(discussionModel): return .Discussion(discussionModel)
        }
    }
}

extension OEXRouter {
    func showCoursewareForCourseWithID(courseID : String, fromController controller : UIViewController) {
        showContainerForBlockWithID(nil, type: CourseBlockDisplayType.Outline, parentID: nil, courseID : courseID, fromController: controller)
    }
    
    func unitControllerForCourseID(courseID : String, blockID : CourseBlockID?, initialChildID : CourseBlockID?) -> CourseContentPageViewController {
        let contentPageController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: blockID, initialChildID: initialChildID)
        return contentPageController
    }
    
    func showContainerForBlockWithID(blockID : CourseBlockID?, type : CourseBlockDisplayType, parentID : CourseBlockID?, courseID : CourseBlockID, fromController controller: UIViewController) {
        switch type {
        case .Outline:
            fallthrough
        case .Unit:
            let outlineController = controllerForBlockWithID(blockID, type: type, courseID: courseID)
            controller.navigationController?.pushViewController(outlineController, animated: true)
        case .HTML:
            fallthrough
        case .Video:
            fallthrough
        case .Unknown:
            let pageController = unitControllerForCourseID(courseID, blockID: parentID, initialChildID: blockID)
            if let delegate = controller as? CourseContentPageViewControllerDelegate {
                pageController.navigationDelegate = delegate
            }
            controller.navigationController?.pushViewController(pageController, animated: true)
        case .Discussion:
            let pageController = unitControllerForCourseID(courseID, blockID: parentID, initialChildID: blockID)
            if let delegate = controller as? CourseContentPageViewControllerDelegate {
                pageController.navigationDelegate = delegate
            }
            controller.navigationController?.pushViewController(pageController, animated: true)
        }
    }
    
    private func controllerForBlockWithID(blockID : CourseBlockID?, type : CourseBlockDisplayType, courseID : String) -> UIViewController {
        switch type {
            case .Outline:
                let outlineController = CourseOutlineViewController(environment: self.environment, courseID: courseID, rootID: blockID)
                return outlineController
        case .Unit:
            return unitControllerForCourseID(courseID, blockID: blockID, initialChildID: nil)
        case .HTML:
            let controller = HTMLBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        case .Video:
            let controller = VideoBlockViewController(environment: environment, blockID: blockID, courseID: courseID)
            return controller
        case .Unknown:
            let controller = CourseUnknownBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        case let .Discussion(discussionModel):
            let controller = DiscussionBlockViewController(blockID: blockID, courseID: courseID, topicID: discussionModel.topicID, environment: environment)
            return controller
        }
    }
    
    func controllerForBlock(block : CourseBlock, courseID : String) -> UIViewController {
        return controllerForBlockWithID(block.blockID, type: block.displayType, courseID: courseID)
    }
    
    @objc(showMyCoursesAnimated:pushingCourseWithID:) func showMyCourses(animated animated: Bool = true, pushingCourseWithID courseID: String? = nil) {
        let controller = EnrolledCoursesViewController(environment: self.environment)
        showContentStackWithRootController(controller, animated: animated)
        if let courseID = courseID {
            self.showCourseWithID(courseID, fromController: controller, animated: false)
        }
    }
    
    func showDiscussionResponsesFromViewController(controller: UIViewController, courseID : String, threadID : String) {
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.environment = environment
        responsesViewController.courseID = courseID
        responsesViewController.threadID = threadID
        controller.navigationController?.pushViewController(responsesViewController, animated: true)
    }
    
    func showDiscussionCommentsFromViewController(controller: UIViewController, courseID : String, response : DiscussionComment, closed : Bool, thread: DiscussionThread) {
        let commentsVC = DiscussionCommentsViewController(environment: environment, courseID : courseID, responseItem: response, closed: closed, thread: thread)
       
        if let delegate = controller as? DiscussionCommentsViewControllerDelegate {
            commentsVC.delegate = delegate
        }
        
        controller.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    func showDiscussionNewCommentFromController(controller: UIViewController, courseID : String, thread:DiscussionThread, context: DiscussionNewCommentViewController.Context) {
        let newCommentViewController = DiscussionNewCommentViewController(environment: environment, courseID : courseID, thread:thread,  context: context)
        
        if let delegate = controller as? DiscussionNewCommentViewControllerDelegate {
            newCommentViewController.delegate = delegate
        }
        
        let navigationController = UINavigationController(rootViewController: newCommentViewController)
        controller.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func showPostsFromController(controller : UIViewController, courseID : String, topic: DiscussionTopic) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, topic: topic)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showAllPostsFromController(controller : UIViewController, courseID : String, followedOnly following : Bool) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, following : following)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showPostsFromController(controller : UIViewController, courseID : String, queryString : String) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, queryString : queryString)
        
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showDiscussionTopicsFromController(controller: UIViewController, courseID : String) {
        let topicsController = DiscussionTopicsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(topicsController, animated: true)
    }

    func showDiscussionNewPostFromController(controller: UIViewController, courseID : String, selectedTopic : DiscussionTopic?) {
        let newPostController = DiscussionNewPostViewController(environment: environment, courseID: courseID, selectedTopic: selectedTopic)
        if let delegate = controller as? DiscussionNewPostViewControllerDelegate {
            newPostController.delegate = delegate
        }
        let navigationController = UINavigationController(rootViewController: newPostController)
        controller.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func showHandoutsFromController(controller : UIViewController, courseID : String) {
        let handoutsViewController = CourseHandoutsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(handoutsViewController, animated: true)
    }

    func showProfileForUsername(controller: UIViewController? = nil, username : String, editable: Bool = true) {
        OEXAnalytics.sharedAnalytics().trackProfileViewed(username)
        let editable = self.environment.session.currentUser?.username == username
        let profileController = UserProfileViewController(environment: environment, username: username, editable: editable)
        if let controller = controller {
            controller.navigationController?.pushViewController(profileController, animated: true)
        } else {
            self.showContentStackWithRootController(profileController, animated: true)
        }
    }
    
    func showProfileEditorFromController(controller : UIViewController) {
        guard let profile = environment.dataManager.userProfileManager.feedForCurrentUser().output.value else {
            return
        }
        let editController = UserProfileEditViewController(profile: profile, environment: environment)
        controller.navigationController?.pushViewController(editController, animated: true)
    }

    func showCertificate(url: NSURL, title: String?, fromController controller: UIViewController) {
        let c = CertificateViewController(environment: environment)
        c.title = title
        controller.navigationController?.pushViewController(c, animated: true)
        c.loadRequest(NSURLRequest(URL: url))
    }
    
    func showCourseWithID(courseID : String, fromController: UIViewController, animated: Bool = true) {
        let controller = CourseDashboardViewController(environment: self.environment, courseID: courseID)
        fromController.navigationController?.pushViewController(controller, animated: animated)
    }
    
    func showCourseCatalog(bottomBar: UIView?) {
        let controller: UIViewController
        switch environment.config.courseEnrollmentConfig.type {
        case .Webview:
            controller = OEXFindCoursesViewController(bottomBar: bottomBar)
        case .Native, .None:
            controller = CourseCatalogViewController(environment: self.environment)
        }
        if revealController != nil {
            showContentStackWithRootController(controller, animated: true)
        } else {
            showControllerFromStartupScreen(controller)
        }
        self.environment.analytics.trackUserFindsCourses()
    }

    func showExploreCourses(bottomBar: UIView?) {
        let controller = OEXFindCoursesViewController(bottomBar: bottomBar)
        controller.startURL = .ExploreSubjects
        if revealController != nil {
            showContentStackWithRootController(controller, animated: true)
        } else {
            showControllerFromStartupScreen(controller)
        }
    }

    private func showControllerFromStartupScreen(controller: UIViewController) {
        let backButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        backButton.oex_setAction({
            controller.dismissViewControllerAnimated(true, completion: nil)
        })
        controller.navigationItem.leftBarButtonItem = backButton
        let navController = ForwardingNavigationController(rootViewController: controller)

        presentViewController(navController, fromController:nil, completion: nil)
    }

    func showCourseCatalogDetail(courseID: String, fromController: UIViewController) {
        let detailController = CourseCatalogDetailViewController(environment: environment, courseID: courseID)
        fromController.navigationController?.pushViewController(detailController, animated: true)
    }
    
    func showAppReviewIfNeeded(fromController: UIViewController) {
        if RatingViewController.canShowAppReview(environment){
            let reviewController = RatingViewController(environment: environment)
            
            reviewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            reviewController.providesPresentationContextTransitionStyle = true
            reviewController.definesPresentationContext = true
            
            fromController.presentViewController(reviewController, animated: false, completion: nil)
        }
    }

    // MARK: - LOGIN / LOGOUT

    func showSplash() {
        revealController = nil
        removeCurrentContentController()

        let splashController: UIViewController
        
        if !environment.config.isRegistrationEnabled {
            splashController = loginViewController()
        }
        else if environment.config.newLogistrationFlowEnabled {
            splashController = StartupViewController(environment: environment)
        } else {
            splashController = OEXLoginSplashViewController(environment: environment)
        }
        
        makeContentControllerCurrent(splashController)
    }

    public func logout() {
        invalidateToken()
        environment.session.closeAndClearSession()
        showLoggedOutScreen()
    }
    
    func invalidateToken() {
        if let refreshToken = environment.session.token?.refreshToken, clientID = environment.config.oauthClientID() {
            let networkRequest = LogoutApi.invalidateToken(refreshToken, clientID: clientID)
            environment.networkManager.taskForRequest(networkRequest) { result in }
        }
    }

    // MARK: - Debug
    func showDebugPane() {
        let debugMenu = DebugMenuViewController(environment: environment)
        showContentStackWithRootController(debugMenu, animated: true)
    }
}


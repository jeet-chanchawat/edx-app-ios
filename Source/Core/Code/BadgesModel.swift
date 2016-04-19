//
//  BadgesModel.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public struct BadgeSpec {

    let slug : String
    let issuingComponent : String?
    let name : String?
    let description : String?
    let imageURL : NSURL?
    let courseID : String?

    private enum Fields : String, RawStringExtractable {
        case Slug = "slug"
        case IssuingComponent = "issuing_component"
        case Name = "name"
        case Description = "description"
        case ImageURL = "image_url"
        case CourseID = "course_id"
    }

    public init?(json : JSON) {
        guard let
            slug = json[Fields.Slug].string
            else {
                return nil
        }
        self.slug = slug
        self.issuingComponent = json[Fields.IssuingComponent].string
        self.name = json[Fields.Name].string
        self.description = json[Fields.Description].string
        self.imageURL = json[Fields.ImageURL].URL
        self.courseID = json[Fields.CourseID].string
    }
}

public struct BadgeAssertion {
    let username : String?
    let evidence : NSURL
    let imageURL : NSURL
    let awardedOn : NSDate?
    let spec : BadgeSpec


    private enum Fields : String, RawStringExtractable {
        case Username = "username"
        case Evidence = "evidence"
        case ImageURL = "image_url"
        case AwardedOn = "awarded_on"
        case Spec = "spec"
    }

    public init?(json : JSON) {
        guard let
            spec = BadgeSpec(json: json[Fields.Spec]),
            evidence = json[Fields.Evidence].URL,
            imageURL = json[Fields.ImageURL].URL ?? spec.imageURL else
        {
                return nil
        }
        self.evidence = evidence
        self.imageURL = imageURL
        self.username = json[Fields.Username].string
        self.awardedOn = json[Fields.AwardedOn].serverDate
        self.spec = spec
    }
}
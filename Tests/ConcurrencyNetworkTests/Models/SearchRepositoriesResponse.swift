//
//  SearchRepositoriesResponse.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/09.
//

import Foundation

// MARK: - SearchRepositoriesResponse
struct SearchRepositoriesResponse: Codable, Equatable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [Item]?

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items = "items"
    }
}

// MARK: - Item
struct Item: Codable, Equatable {
    let id: Int
    let nodeId: String
    let name: String
    let fullName: String
    let itemPrivate: Bool
    let owner: Owner
    let htmlUrl: String
    let description: String?
    let fork: Bool
    let url: String
    let forksUrl: String
    let keysUrl: String
    let collaboratorsUrl: String
    let teamsUrl: String
    let hooksUrl: String
    let issueEventsUrl: String
    let eventsUrl: String
    let assigneesUrl: String
    let branchesUrl: String
    let tagsUrl: String
    let blobsUrl: String
    let gitTagsUrl: String
    let gitRefsUrl: String
    let treesUrl: String
    let statusesUrl: String
    let languagesUrl: String
    let stargazersUrl: String
    let contributorsUrl: String
    let subscribersUrl: String
    let subscriptionUrl: String
    let commitsUrl: String
    let gitCommitsUrl: String
    let commentsUrl: String
    let issueCommentUrl: String
    let contentsUrl: String
    let compareUrl: String
    let mergesUrl: String
    let archiveUrl: String
    let downloadsUrl: String
    let issuesUrl: String
    let pullsUrl: String
    let milestonesUrl: String
    let notificationsUrl: String
    let labelsUrl: String
    let releasesUrl: String
    let deploymentsUrl: String
    let createdAt: Date
    let updatedAt: Date
    let pushedAt: Date
    let gitUrl: String
    let sshUrl: String
    let cloneUrl: String
    let svnUrl: String
    let homepage: String?
    let size: Int
    let stargazersCount: Int
    let watchersCount: Int
    let language: String?
    let hasIssues: Bool
    let hasProjects: Bool
    let hasDownloads: Bool
    let hasWiki: Bool
    let hasPages: Bool
    let hasDiscussions: Bool
    let forksCount: Int
//    let mirrorUrl: JSONNull?
    let archived: Bool
    let disabled: Bool
    let openIssuesCount: Int
    let license: License?
    let allowForking: Bool
    let isTemplate: Bool
    let webCommitSignoffRequired: Bool
    let topics: [String]
    let visibility: String
    let forks: Int
    let openIssues: Int
    let watchers: Int
    let defaultBranch: String
    let score: Int

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case nodeId = "node_id"
        case name = "name"
        case fullName = "full_name"
        case itemPrivate = "private"
        case owner = "owner"
        case htmlUrl = "html_url"
        case description = "description"
        case fork = "fork"
        case url = "url"
        case forksUrl = "forks_url"
        case keysUrl = "keys_url"
        case collaboratorsUrl = "collaborators_url"
        case teamsUrl = "teams_url"
        case hooksUrl = "hooks_url"
        case issueEventsUrl = "issue_events_url"
        case eventsUrl = "events_url"
        case assigneesUrl = "assignees_url"
        case branchesUrl = "branches_url"
        case tagsUrl = "tags_url"
        case blobsUrl = "blobs_url"
        case gitTagsUrl = "git_tags_url"
        case gitRefsUrl = "git_refs_url"
        case treesUrl = "trees_url"
        case statusesUrl = "statuses_url"
        case languagesUrl = "languages_url"
        case stargazersUrl = "stargazers_url"
        case contributorsUrl = "contributors_url"
        case subscribersUrl = "subscribers_url"
        case subscriptionUrl = "subscription_url"
        case commitsUrl = "commits_url"
        case gitCommitsUrl = "git_commits_url"
        case commentsUrl = "comments_url"
        case issueCommentUrl = "issue_comment_url"
        case contentsUrl = "contents_url"
        case compareUrl = "compare_url"
        case mergesUrl = "merges_url"
        case archiveUrl = "archive_url"
        case downloadsUrl = "downloads_url"
        case issuesUrl = "issues_url"
        case pullsUrl = "pulls_url"
        case milestonesUrl = "milestones_url"
        case notificationsUrl = "notifications_url"
        case labelsUrl = "labels_url"
        case releasesUrl = "releases_url"
        case deploymentsUrl = "deployments_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
        case gitUrl = "git_url"
        case sshUrl = "ssh_url"
        case cloneUrl = "clone_url"
        case svnUrl = "svn_url"
        case homepage = "homepage"
        case size = "size"
        case stargazersCount = "stargazers_count"
        case watchersCount = "watchers_count"
        case language = "language"
        case hasIssues = "has_issues"
        case hasProjects = "has_projects"
        case hasDownloads = "has_downloads"
        case hasWiki = "has_wiki"
        case hasPages = "has_pages"
        case hasDiscussions = "has_discussions"
        case forksCount = "forks_count"
//        case mirrorUrl = "mirror_url"
        case archived = "archived"
        case disabled = "disabled"
        case openIssuesCount = "open_issues_count"
        case license = "license"
        case allowForking = "allow_forking"
        case isTemplate = "is_template"
        case webCommitSignoffRequired = "web_commit_signoff_required"
        case topics = "topics"
        case visibility = "visibility"
        case forks = "forks"
        case openIssues = "open_issues"
        case watchers = "watchers"
        case defaultBranch = "default_branch"
        case score = "score"
    }
}

// MARK: - License
struct License: Codable, Equatable {
    let key: String
    let name: String
    let spdxId: String
    let url: String?
    let nodeId: String

    enum CodingKeys: String, CodingKey {
        case key = "key"
        case name = "name"
        case spdxId = "spdx_id"
        case url = "url"
        case nodeId = "node_id"
    }
}

// MARK: - Owner
struct Owner: Codable, Equatable {
    let login: String
    let id: Int
    let nodeId: String
    let avatarUrl: String
    let gravatarId: String
    let url: String
    let htmlUrl: String
    let followersUrl: String
    let followingUrl: String
    let gistsUrl: String
    let starredUrl: String
    let subscriptionsUrl: String
    let organizationsUrl: String
    let reposUrl: String
    let eventsUrl: String
    let receivedEventsUrl: String
    let type: String
    let siteAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case login = "login"
        case id = "id"
        case nodeId = "node_id"
        case avatarUrl = "avatar_url"
        case gravatarId = "gravatar_id"
        case url = "url"
        case htmlUrl = "html_url"
        case followersUrl = "followers_url"
        case followingUrl = "following_url"
        case gistsUrl = "gists_url"
        case starredUrl = "starred_url"
        case subscriptionsUrl = "subscriptions_url"
        case organizationsUrl = "organizations_url"
        case reposUrl = "repos_url"
        case eventsUrl = "events_url"
        case receivedEventsUrl = "received_events_url"
        case type = "type"
        case siteAdmin = "site_admin"
    }
}

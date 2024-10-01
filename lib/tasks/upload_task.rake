# frozen_string_literal: true

return unless Rails.env.development?

namespace :upload_job_test do
  desc 'Test trigger the UploadJob'
  task trigger: :environment do
    # Paste in a payload from the GitHub webhook (https://github.com/organizations/raspberrypilearning/settings/hooks)
    payload = {
      ref: 'refs/heads/draft',
      before: '4c751b19488a0a6b4cbe4d86d27a63598b0dbf33',
      after: '477420b5822859d5b39b907f122ec51d227b2448',
      repository: {
        id: 860_323_001,
        node_id: 'R_kgDOM0d8uQ',
        name: 'test-project-dh',
        full_name: 'raspberrypilearning/test-project-dh',
        private: false,
        owner: {
          name: 'raspberrypilearning',
          email: nil,
          login: 'raspberrypilearning',
          id: 6_546_294,
          node_id: 'MDEyOk9yZ2FuaXphdGlvbjY1NDYyOTQ=',
          avatar_url: 'https://avatars.githubusercontent.com/u/6546294?v=4',
          gravatar_id: '',
          url: 'https://api.github.com/users/raspberrypilearning',
          html_url: 'https://github.com/raspberrypilearning',
          followers_url: 'https://api.github.com/users/raspberrypilearning/followers',
          following_url: 'https://api.github.com/users/raspberrypilearning/following{/other_user}',
          gists_url: 'https://api.github.com/users/raspberrypilearning/gists{/gist_id}',
          starred_url: 'https://api.github.com/users/raspberrypilearning/starred{/owner}{/repo}',
          subscriptions_url: 'https://api.github.com/users/raspberrypilearning/subscriptions',
          organizations_url: 'https://api.github.com/users/raspberrypilearning/orgs',
          repos_url: 'https://api.github.com/users/raspberrypilearning/repos',
          events_url: 'https://api.github.com/users/raspberrypilearning/events{/privacy}',
          received_events_url: 'https://api.github.com/users/raspberrypilearning/received_events',
          type: 'Organization',
          site_admin: false
        },
        html_url: 'https://github.com/raspberrypilearning/test-project-dh',
        description: nil,
        fork: false,
        url: 'https://github.com/raspberrypilearning/test-project-dh',
        forks_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/forks',
        keys_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/keys{/key_id}',
        collaborators_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/collaborators{/collaborator}',
        teams_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/teams',
        hooks_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/hooks',
        issue_events_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/issues/events{/number}',
        events_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/events',
        assignees_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/assignees{/user}',
        branches_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/branches{/branch}',
        tags_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/tags',
        blobs_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/git/blobs{/sha}',
        git_tags_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/git/tags{/sha}',
        git_refs_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/git/refs{/sha}',
        trees_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/git/trees{/sha}',
        statuses_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/statuses/{sha}',
        languages_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/languages',
        stargazers_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/stargazers',
        contributors_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/contributors',
        subscribers_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/subscribers',
        subscription_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/subscription',
        commits_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/commits{/sha}',
        git_commits_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/git/commits{/sha}',
        comments_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/comments{/number}',
        issue_comment_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/issues/comments{/number}',
        contents_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/contents/{+path}',
        compare_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/compare/{base}...{head}',
        merges_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/merges',
        archive_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/{archive_format}{/ref}',
        downloads_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/downloads',
        issues_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/issues{/number}',
        pulls_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/pulls{/number}',
        milestones_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/milestones{/number}',
        notifications_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/notifications{?since,all,participating}',
        labels_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/labels{/name}',
        releases_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/releases{/id}',
        deployments_url: 'https://api.github.com/repos/raspberrypilearning/test-project-dh/deployments',
        created_at: 1_726_820_154,
        updated_at: '2024-09-20T08:15:59Z',
        pushed_at: 1_726_838_069,
        git_url: 'git://github.com/raspberrypilearning/test-project-dh.git',
        ssh_url: 'git@github.com:raspberrypilearning/test-project-dh.git',
        clone_url: 'https://github.com/raspberrypilearning/test-project-dh.git',
        svn_url: 'https://github.com/raspberrypilearning/test-project-dh',
        homepage: nil,
        size: 93,
        stargazers_count: 0,
        watchers_count: 0,
        language: nil,
        has_issues: true,
        has_projects: true,
        has_downloads: true,
        has_wiki: true,
        has_pages: false,
        has_discussions: false,
        forks_count: 0,
        mirror_url: nil,
        archived: false,
        disabled: false,
        open_issues_count: 0,
        license: {
          key: 'other',
          name: 'Other',
          spdx_id: 'NOASSERTION',
          url: nil,
          node_id: 'MDc6TGljZW5zZTA='
        },
        allow_forking: true,
        is_template: false,
        web_commit_signoff_required: false,
        topics: [],
        visibility: 'public',
        forks: 0,
        open_issues: 0,
        watchers: 0,
        default_branch: 'master',
        stargazers: 0,
        master_branch: 'master',
        organization: 'raspberrypilearning',
        custom_properties: {}
      },
      pusher: {
        name: 'danhalson',
        email: 'danhalson@users.noreply.github.com'
      },
      organization: {
        login: 'raspberrypilearning',
        id: 6_546_294,
        node_id: 'MDEyOk9yZ2FuaXphdGlvbjY1NDYyOTQ=',
        url: 'https://api.github.com/orgs/raspberrypilearning',
        repos_url: 'https://api.github.com/orgs/raspberrypilearning/repos',
        events_url: 'https://api.github.com/orgs/raspberrypilearning/events',
        hooks_url: 'https://api.github.com/orgs/raspberrypilearning/hooks',
        issues_url: 'https://api.github.com/orgs/raspberrypilearning/issues',
        members_url: 'https://api.github.com/orgs/raspberrypilearning/members{/member}',
        public_members_url: 'https://api.github.com/orgs/raspberrypilearning/public_members{/member}',
        avatar_url: 'https://avatars.githubusercontent.com/u/6546294?v=4',
        description: 'Learning Resources and Projects provided by the Raspberry Pi Foundation'
      },
      sender: {
        login: 'danhalson',
        id: 2_422_897,
        node_id: 'MDQ6VXNlcjI0MjI4OTc=',
        avatar_url: 'https://avatars.githubusercontent.com/u/2422897?v=4',
        gravatar_id: '',
        url: 'https://api.github.com/users/danhalson',
        html_url: 'https://github.com/danhalson',
        followers_url: 'https://api.github.com/users/danhalson/followers',
        following_url: 'https://api.github.com/users/danhalson/following{/other_user}',
        gists_url: 'https://api.github.com/users/danhalson/gists{/gist_id}',
        starred_url: 'https://api.github.com/users/danhalson/starred{/owner}{/repo}',
        subscriptions_url: 'https://api.github.com/users/danhalson/subscriptions',
        organizations_url: 'https://api.github.com/users/danhalson/orgs',
        repos_url: 'https://api.github.com/users/danhalson/repos',
        events_url: 'https://api.github.com/users/danhalson/events{/privacy}',
        received_events_url: 'https://api.github.com/users/danhalson/received_events',
        type: 'User',
        site_admin: false
      },
      created: false,
      deleted: false,
      forced: false,
      base_ref: nil,
      compare: 'https://github.com/raspberrypilearning/test-project-dh/compare/4c751b19488a...477420b58228',
      commits: [
        {
          id: '477420b5822859d5b39b907f122ec51d227b2448',
          tree_id: 'decae51495ca1df2ce4ec322fbc5ff1bcd768528',
          distinct: true,
          message: 'Create test.py',
          timestamp: '2024-09-20T14:14:29+01:00',
          url: 'https://github.com/raspberrypilearning/test-project-dh/commit/477420b5822859d5b39b907f122ec51d227b2448',
          author: {
            name: 'Dan Halson',
            email: 'danhalson@users.noreply.github.com',
            username: 'danhalson'
          },
          committer: {
            name: 'GitHub',
            email: 'noreply@github.com',
            username: 'web-flow'
          },
          added: [
            'en/code/test.py'
          ],
          removed: [],
          modified: []
        }
      ],
      head_commit: {
        id: '477420b5822859d5b39b907f122ec51d227b2448',
        tree_id: 'decae51495ca1df2ce4ec322fbc5ff1bcd768528',
        distinct: true,
        message: 'Create test.py',
        timestamp: '2024-09-20T14:14:29+01:00',
        url: 'https://github.com/raspberrypilearning/test-project-dh/commit/477420b5822859d5b39b907f122ec51d227b2448',
        author: {
          name: 'Dan Halson',
          email: 'danhalson@users.noreply.github.com',
          username: 'danhalson'
        },
        committer: {
          name: 'GitHub',
          email: 'noreply@github.com',
          username: 'web-flow'
        },
        added: [
          'en/code/test.py'
        ],
        removed: [],
        modified: []
      }
    }

    abort('Stopping as no payload was provided (expects a payload from the GitHub webhook: https://github.com/organizations/raspberrypilearning/settings/hooks)') if payload.blank?

    if edited_code?(payload)
      UploadJob.perform_now(payload)
    else
      abort('Stopping as nothing under `/code` was edited in the push')
    end
  end

  def edited_code?(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten
    modified_paths.count { |path| path.split('/')[1] == 'code' }.positive?
  end
end

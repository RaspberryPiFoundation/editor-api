# frozen_string_literal: true

return unless Rails.env.development?

namespace :upload_job_test do
  desc 'Test trigger the UploadJob'
  task trigger: :environment do
    # Paste in a payload from the GitHub webhook (https://github.com/organizations/raspberrypilearning/settings/hooks)
    payload = {
      ref: 'refs/heads/draft',
      before: '2103d88ed0dfe731720d89a2ab10ea5092042c5f',
      after: '1d1e19b5e628daac87567894cdaf80e96b281b0c',
      repository: {
        id: 866_981_774,
        node_id: 'R_kgDOM60Xjg',
        name: 'test-template-build-sa',
        full_name: 'raspberrypilearning/test-template-build-sa',
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
        html_url: 'https://github.com/raspberrypilearning/test-template-build-sa',
        description: nil,
        fork: false,
        url: 'https://github.com/raspberrypilearning/test-template-build-sa',
        forks_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/forks',
        keys_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/keys{/key_id}',
        collaborators_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/collaborators{/collaborator}',
        teams_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/teams',
        hooks_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/hooks',
        issue_events_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/issues/events{/number}',
        events_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/events',
        assignees_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/assignees{/user}',
        branches_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/branches{/branch}',
        tags_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/tags',
        blobs_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/git/blobs{/sha}',
        git_tags_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/git/tags{/sha}',
        git_refs_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/git/refs{/sha}',
        trees_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/git/trees{/sha}',
        statuses_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/statuses/{sha}',
        languages_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/languages',
        stargazers_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/stargazers',
        contributors_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/contributors',
        subscribers_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/subscribers',
        subscription_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/subscription',
        commits_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/commits{/sha}',
        git_commits_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/git/commits{/sha}',
        comments_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/comments{/number}',
        issue_comment_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/issues/comments{/number}',
        contents_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/contents/{+path}',
        compare_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/compare/{base}...{head}',
        merges_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/merges',
        archive_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/{archive_format}{/ref}',
        downloads_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/downloads',
        issues_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/issues{/number}',
        pulls_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/pulls{/number}',
        milestones_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/milestones{/number}',
        notifications_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/notifications{?since,all,participating}',
        labels_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/labels{/name}',
        releases_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/releases{/id}',
        deployments_url: 'https://api.github.com/repos/raspberrypilearning/test-template-build-sa/deployments',
        created_at: 1_727_944_474,
        updated_at: '2024-10-03T08:34:39Z',
        pushed_at: 1_727_944_734,
        git_url: 'git://github.com/raspberrypilearning/test-template-build-sa.git',
        ssh_url: 'git@github.com:raspberrypilearning/test-template-build-sa.git',
        clone_url: 'https://github.com/raspberrypilearning/test-template-build-sa.git',
        svn_url: 'https://github.com/raspberrypilearning/test-template-build-sa',
        homepage: nil,
        size: 0,
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
        name: 'sra405',
        email: '74183390+sra405@users.noreply.github.com'
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
        login: 'sra405',
        id: 74_183_390,
        node_id: 'MDQ6VXNlcjc0MTgzMzkw',
        avatar_url: 'https://avatars.githubusercontent.com/u/74183390?v=4',
        gravatar_id: '',
        url: 'https://api.github.com/users/sra405',
        html_url: 'https://github.com/sra405',
        followers_url: 'https://api.github.com/users/sra405/followers',
        following_url: 'https://api.github.com/users/sra405/following{/other_user}',
        gists_url: 'https://api.github.com/users/sra405/gists{/gist_id}',
        starred_url: 'https://api.github.com/users/sra405/starred{/owner}{/repo}',
        subscriptions_url: 'https://api.github.com/users/sra405/subscriptions',
        organizations_url: 'https://api.github.com/users/sra405/orgs',
        repos_url: 'https://api.github.com/users/sra405/repos',
        events_url: 'https://api.github.com/users/sra405/events{/privacy}',
        received_events_url: 'https://api.github.com/users/sra405/received_events',
        type: 'User',
        site_admin: false
      },
      created: false,
      deleted: false,
      forced: false,
      base_ref: nil,
      compare: 'https://github.com/raspberrypilearning/test-template-build-sa/compare/2103d88ed0df...1d1e19b5e628',
      commits: [
        {
          id: '1d1e19b5e628daac87567894cdaf80e96b281b0c',
          tree_id: 'c6575aadb5146cbb26c061cbe5ef16bc4376373e',
          distinct: true,
          message: 'nil change',
          timestamp: '2024-10-03T09:38:53+01:00',
          url: 'https://github.com/raspberrypilearning/test-template-build-sa/commit/1d1e19b5e628daac87567894cdaf80e96b281b0c',
          author: {
            name: 'Scott Adams',
            email: '74183390+sra405@users.noreply.github.com',
            username: 'sra405'
          },
          committer: {
            name: 'GitHub',
            email: 'noreply@github.com',
            username: 'web-flow'
          },
          added: [],
          removed: [],
          modified: [
            'en/code/code-project-example/project_config.yml'
          ]
        }
      ],
      head_commit: {
        id: '1d1e19b5e628daac87567894cdaf80e96b281b0c',
        tree_id: 'c6575aadb5146cbb26c061cbe5ef16bc4376373e',
        distinct: true,
        message: 'nil change',
        timestamp: '2024-10-03T09:38:53+01:00',
        url: 'https://github.com/raspberrypilearning/test-template-build-sa/commit/1d1e19b5e628daac87567894cdaf80e96b281b0c',
        author: {
          name: 'Scott Adams',
          email: '74183390+sra405@users.noreply.github.com',
          username: 'sra405'
        },
        committer: {
          name: 'GitHub',
          email: 'noreply@github.com',
          username: 'web-flow'
        },
        added: [],
        removed: [],
        modified: [
          'en/code/code-project-example/project_config.yml'
        ]
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

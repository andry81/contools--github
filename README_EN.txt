* README_EN.txt
* 2024.05.24
* contools--github

1. DESCRIPTION
2. CATALOG CONTENT DESCRIPTION
3. USAGE
3.1. Generate config files
3.2. Edit generated config files
3.3. Run RestAPI JSON response backup scripts
3.4. Run repositories backup
3.5. Delete repositories
3.6. Run workflows enabler
3.7. Generate `workflows.lst` config file from the all latest backed up
     RestAPI JSON files using `repos-auth-with-workflows.lst` and
     `repos-with-workflows.lst` config files.
4. AUTHENTICATION
5. KNOWN ISSUES
5.1. The `backup_restapi_user_repos_list.bat` script does return incomplete
     RestAPI JSON response. Not all the public repositories is returned.
6. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
Github local scripts to:
* Backup RestAPI JSON responses.
* Backup bare or/and checkouted repositories.
* Delete repositories.
* Workflow enable.
* Generate config files from backed up RestAPI JSON files.

-------------------------------------------------------------------------------
2. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>
 |
 +- /`.log`
 |    #
 |    # Log files directory, where does store all log files from all scripts
 |    # including all nested projects.
 |
 +- /`_config`
 |    #
 |    # Directory with input configuration files.
 |
 +- /`_out`
 |  | #
 |  | # Output directory for all files.
 |  |
 |  +- /`config`
 |  |  | #
 |  |  | # Output directory for all configuration files.
 |  |  |
 |  |  +- /`contools--github`
 |  |     | #
 |  |     | # Output directory for the scripts configuration files.
 |  |     |
 |  |     +- `accounts-org.lst`
 |  |     |   #
 |  |     |   # User organization accounts.
 |  |     |
 |  |     +- `accounts-user.lst`
 |  |     |   #
 |  |     |   # User accounts.
 |  |     |
 |  |     +- `repos.lst`
 |  |     |   #
 |  |     |   # User repositories list.
 |  |     |
 |  |     +- `repos-auth.lst`
 |  |     |   #
 |  |     |   # Authenticated only user repositories list.
 |  |     |
 |  |     +- `repos-auth-with-workflows.lst`
 |  |     |   #
 |  |     |   # Authenticated only user repositories with workflows list.
 |  |     |
 |  |     +- `repos-forks.lst`
 |  |     |   #
 |  |     |   # User forked repositories list.
 |  |     |
 |  |     +- `repos-to-delete.lst`
 |  |     |   #
 |  |     |   # User repositories to delete.
 |  |     |
 |  |     +- `repos-with-workflows.lst`
 |  |     |   #
 |  |     |   # User repositories with workflows list.
 |  |     |
 |  |     +- `workflows.lst`
 |  |     |   #
 |  |     |   # User workflows.
 |  |     |
 |  |     +- `config.0.vars`
 |  |     |   #
 |  |     |   # Scripts public environment variables.
 |  |     |
 |  |     +- `config.1.vars`
 |  |         #
 |  |         # Scripts private environment variables.
 |  |
 |  +- /`backup`
 |  |  | #
 |  |  | # Output directory for github repository backup files.
 |  |  |
 |  |  +- /`bare`
 |  |  |    #
 |  |  |    # Output directory for backup bare with or without checkout
 |  |  |    # repositories.
 |  |  |
 |  |  +- /`checkouted`
 |  |  |    #
 |  |  |    # Output directory for backup only checkouted repositories.
 |  |  |
 |  |  +- /`restapi`
 |  |       #
 |  |       # Output directory for backup RestAPI JSON responses.
 |  |
 |  +- /`workflow`
 |       #
 |       # Output directory for github repository workflow files.
 |
 +- `/scripts/*.bat`
     #
     # Scripts.

-------------------------------------------------------------------------------
3. USAGE
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
3.1. Generate config files
-------------------------------------------------------------------------------

Run:

  >
  __init__/__init__.bat

-------------------------------------------------------------------------------
3.2. Edit generated config files
-------------------------------------------------------------------------------

accounts-org.lst
accounts-user.lst
repos.lst
repos-auth.lst
repos-auth-with-workflows.lst
repos-forks.lst
repos-with-workflows.lst
workflows.lst
config.0.vars
config.1.vars

-------------------------------------------------------------------------------
3.3. Run RestAPI JSON response backup scripts
-------------------------------------------------------------------------------

To backup all RestAPI JSON responses for authenticated user plus accounts from
`accounts-user.lst`:

  >
  backup_restapi_all_user_repos_list.bat

To backup RestAPI JSON responses only for user organization accounts from
`accounts-org.lst`:

  >
  backup_restapi_all_org_repos_list.bat

To backup using previous 2 with `user repo info`, `stargazers`, `subscribers`,
`forks`, `releases` using `repos.lst` and/or `repos-forks.lst`.

  >
  backup_restapi_all.bat

To backup all RestAPI JSON responses except repository list for user and
organization accounts. Or the same as `backup_restapi_all.bat` script but
excluding first 2 scripts:

  >
  backup_restapi_all_exclude_repos_list.bat

-------------------------------------------------------------------------------
3.4. Run repositories backup
-------------------------------------------------------------------------------

To backup a single user repository:

  >
  backup_bare_*_repo.bat ...
  backup_bared_checkout_*_repo.bat ...
  backup_checkouted_*_repo.bat ...

To backup multiple user repositories:

  >
  backup_bare_all*_repos.bat ...
  backup_bared_checkout_all*_repos.bat ...
  backup_checkouted_all*_repos.bat ...

To backup only bare repositor(ies):

  >
  backup_bare_*.bat ...

To backup only recursively checkouted repositor(ies):

  >
  backup_checkouted_*.bat ...

To backup repositor(ies) as bare plus with recursed checkout:

  >
  backup_bared_checkout_*.bat ...

To backup a single only authenticated user repository:

  >
  backup_*_auth_repo.bat ...

To backup multiple user repositories from `repos.lst` and/or `repos-forks.lst`:

  >
  backup_*_all_repos.bat ...

To backup multiple only authenticated user repositories from `repos-auth.lst`:

  >
  backup_*_all_auth_repos.bat ...

-------------------------------------------------------------------------------
3.5. Delete repositories
-------------------------------------------------------------------------------

To delete a single user repository:

  >
  delete_restapi_user_repo.bat ...

To delete multiple user repositories from `repos-to-delete.lst`:

  >
  delete_restapi_user_repos.bat ...

-------------------------------------------------------------------------------
3.6. Run workflows enabler
-------------------------------------------------------------------------------

To be able to enable multiple user repository workflow lists:

  1. Generate `workflows.lst` config file (see below).

To enable a single user repository workflow:

  >
  enable_restapi_user_repo_workflow.bat ...

To enable multiple user repository workflow lists:

  >
  enable_restapi_workflows.bat ...

-------------------------------------------------------------------------------
3.7. Generate `workflows.lst` config file from the all latest backed up
     RestAPI JSON files using `repos-auth-with-workflows.lst` and
     `repos-with-workflows.lst` config files.
-------------------------------------------------------------------------------

To be able to backup multiple user repository workflow lists, update these
configuration files:

  * `repos-auth-with-workflows.lst`
  * `repos-with-workflows.lst`

To backup a single user repository workflow list:

  >
  backup_restapi_repo_workflows_list.bat ...

To backup multiple user repository workflow lists:

  >
  backup_restapi_all_repo_workflows_list.bat

To generate `workflows.lst` config file:

  >
  gen_workflows_config_from_last_backup.bat ...

-------------------------------------------------------------------------------
4. AUTHENTICATION
-------------------------------------------------------------------------------
Authentication is based on `GH_AUTH_USER`. `GH_AUTH_PASS` and `GH_AUTH_PASS_*`
variables. You must set them to use authentication, otherwise the RestAPI JSON
response may be truncated, incomplete or invalid.

-------------------------------------------------------------------------------
5. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
5.1. The `backup_restapi_user_repos_list.bat` script does return incomplete
     RestAPI JSON response. Not all the public repositories is returned.
-------------------------------------------------------------------------------
For some not know reason the `https://api.github.com/users/USER/repos` url
does return an incomplete RestAPI JSON response even for the authenticated
user.

Solution:

Use the authenticated user request through the
`backup_restapi_auth_user_repos_list.bat` script. It does use authentication
and `https://api.github.com/user/repos` url as the RestAPI JSON request.

-------------------------------------------------------------------------------
6. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)

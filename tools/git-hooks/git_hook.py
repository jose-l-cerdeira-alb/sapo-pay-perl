#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Recipes:
    -se o checkout do branch svn falhar depois create_branch
        $git checkout -b <branch> origin/<branch>
    -forçar um git svn commit
        $git svn dcommit
"""
import sys
import os
from os.path import join, dirname, realpath, isdir, isfile, exists, expanduser
from os import getcwd, chdir
import errno
import shutil
import re
from pathlib import PurePath
from subprocess import Popen, PIPE
from hashlib import sha256
from collections import namedtuple
from git import Repo
import pexpect
import yaml
import pycurl


JENKINS_URL = 'https://{0}:{1}@{2}/job/{3}/build?token={4}'

# from "release/18.04.1.999-hotfix0" matches "18.04.1.999"
REQ = r'(([0-9]{2})\.([0-9]{2})\.([0-9]{1,2})\.([\d]+))'

UNSUPPORTED = 'Unsupported option "{0}"'

Branch = namedtuple('Branch', 'git svn')

Info = namedtuple('Info', 'path type to')
Changed = namedtuple('Changed', 'added changed deleted renamed')


def rel(name):
    if name.find(' ') == -1:
        return join('src', name)
    return join('src', '"{}"'.format(name))


def list_files(func):
    """
    """
    def func_wrapper(self, *args, **kwargs):
        if self.config.get('verbose'):
            if self.config['verbose']:
                print(self.git.branch)
                print(self.branch.svn)
                print('Changed')
                print(self.git.list_changed_files())
                print('Deleted')
                print(self.git.list_deleted_files())
                print('Renamed')
                print(self.git.list_renamed_files())
                # print('merged ' + self.git.merged_branch())
        return func(self, *args, **kwargs)
    return func_wrapper


def ensure_path(func):
    def func_wrapper(self, *args, **kwargs):
        cwd = getcwd()
        try:
            # wd = expanduser(self.config['gitsvn_path'])
            wd = expanduser(self.path)
            chdir(wd)
            # print('"""' + wd + '"""')
            ret = func(self, *args, **kwargs)
            chdir(cwd)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        return ret
    return func_wrapper


def ensure_copy_path(func):
    def func_wrapper(self, *args, **kwargs):
        cwd = getcwd()
        try:
            wd = join(expanduser(self.path), 'src')
            chdir(wd)
            # print(getcwd())
            ret = func(self, *args, **kwargs)
            chdir(cwd)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        return ret
    return func_wrapper


def call_jenkins(url, ignore_ssl=False, timeout=60):
    """
    Continuous integration with Jenkins
    """
    curl = pycurl.Curl()
    try:
        curl.setopt(pycurl.URL, url)
        curl.setopt(pycurl.HTTPGET, 1)
        curl.setopt(pycurl.FOLLOWLOCATION, True)
        if ignore_ssl:
            curl.setopt(pycurl.SSL_VERIFYHOST, False)
            curl.setopt(pycurl.SSL_VERIFYPEER, False)
        curl.setopt(pycurl.TIMEOUT, timeout)
        curl.setopt(pycurl.CONNECTTIMEOUT, timeout)
        curl.perform()
        return True
    except pycurl.error as e:
        # print(url)
        raise e
    return False


def normalize_name(name):
    """
    new
    """
    return name.replace('/', '_')


def configuration():
    """
    Config file reader
    """
    path = realpath(__file__)  # ~/project/sapopay/.git'
    path = join(dirname(path), "config.yml")
    if isfile(path):
        with open(path, 'r') as stream:
            try:
                return yaml.load(stream)
            except yaml.YAMLError as e:
                pass

    default = {
        'timeout': 60,
        'verbose': False,
        'dry-run': True,
        'gitsvn_path': '[git svn path]',
        'svn': 'http://svn.ptin.corppt.com/repo/xwallet',
        'integration': True,  # calls jenkins if true
        'ignore': [
            '.gitignore',
            '**/t-payment.pl',
            '**/*.lock',
            ],
        'branches': [
            {
                'name': 'release/*',
                'ignore': False,
                },
            {
                'name': 'master',
                'ignore': False,
                }
            ],
        'jenkins': {
            'branch': 'staging',
            'ignore_ssl': True,
            'url': 'vm-pay06.vmdev.bk.sapo.pt/jenkins',
            'job': 'staging',
            'token': '90c7cce08f5d11e89eadb4b52fccbb10',
            'user': 'automator',
            'authorization': 'eebf6ffb12cae27c19179b6e15831fe6'
            }
        }
    with open(path, 'w') as config_file:
        yaml.dump(default, config_file, default_flow_style=False)
    return default


def src_dir():
    """
    finds the root dir of a git repository
    """
    src = realpath(__file__)    # beca/beca/repo/.git/hooks/my_hook
    while not isdir(join(src, '.git')):
        src = dirname(src)
        # print(src)
        if src == '/':
            raise IOError
    return src


class GitSVNException(Exception):
    pass


class Copier():
    def __init__(self, config):
        self.config = config
        if self.config.get('verbose'):
            self.verbose = self.config['verbose']
        else:
            self.verbose = False

    def _ignored(self, filename):
        for mask in self.config['ignore']:
            if PurePath(filename).match(mask):
                return True
        return False

    def _sha256_checksum(self, filename, block_size=65536):
        hash = sha256()
        with open(filename, 'rb') as f:
            for block in iter(lambda: f.read(block_size), b''):
                hash.update(block)
        return hash.hexdigest()

    def same_file(self, src, dest):
        if os.path.exists(dest):
            return self._sha256_checksum(src) == self._sha256_checksum(dest)
        return False

    def copy_files(self, files):
        src_path = self.config['git_path']
        dest = join(expanduser(self.config['gitsvn_path']), 'src')

        for name in files:
            if self._ignored(name):
                continue

            src = os.path.join(src_path, name)
            if os.path.isfile(src):
                tofile = os.path.join(dest, name)
                folder = dirname(tofile)

                if not os.path.exists(folder):
                    try:
                        os.makedirs(folder)
                    except IOError as e:
                        print("Unable to create directory. %s" % e)
                        raise e

                try:
                    if self.same_file(src, tofile):
                        continue
                    if self.verbose:
                        print("from: " + src)
                        print("  to: " + tofile)

                    shutil.copy(src, tofile)
                except IOError as e:
                    print("Unable to copy file. %s" % e)
                    raise e


class GitRepo(object):
    def __init__(self, config, head=None):
        self.config = config
        self.path = None
        self._head = head
        self.repo = None
        self.status = None
        self.sub = '.'
        if self.config.get('verbose'):
            self.verbose = self.config['verbose']
        else:
            self.verbose = False

    def _pexpect_exception(self, e):
        lines = e.get_trace()
        print('Exception ' + e.__class__.__name__)
        print(lines)
        self.status = 255

    def _print_error(self, error=None):
        if error is None:
            error = 'Something went wrong\nTente mais tarde'
        print(error)

    @ensure_path
    def _subprocess(self, args):
        p = Popen(args, stdout=PIPE)
        self.status = p.wait()
        return p.stdout

    def print_output(self, txt):
        output = txt.decode("utf-8")
        lines = [f.strip() for f in output.split('\r')]
        for line in lines:
            print(line)

    @ensure_path
    def _expect(self, cmd, what, silent=False):
        try:
            print(cmd)
            print(getcwd())
            child = pexpect.spawn(cmd)
            i = child.expect(what, timeout=self.config['timeout'])
            # child.wait()
            # if not silent:
            output = child.before + child.after + child.read()
            self.print_output(output)
            if type(what) is list:
                return i < len(what)
            if i == 0:
                return True
        except pexpect.EOF as e:
            if not silent:
                self._pexpect_exception(e)
        except pexpect.TIMEOUT as e:
            self._pexpect_exception(e)
        return False

    @ensure_path
    def _run(self, cmd, events=None):
        try:

            (output, status) = pexpect.run(cmd,
                                           events,
                                           withexitstatus=1)
            if len(output) > 0:
                self.print_output(output)
            # print(cmd)
            # print(status)
            # print(output)
            return status
        except pexpect.EOF as e:
            self._pexpect_exception(e)
        except pexpect.TIMEOUT as e:
            self._pexpect_exception(e)
        return -1

    def default_(self, args):
        return self._subprocess(args)

    def default_if_none(self, value):
        if value is None:
            return '.'
        return value

    def get_issue(self):
        if self.branch is not None:
            # release/18.04.1.123-hotfix9
            m = re.search(REQ, self.branch)

            if m is not None:
                r = m.group(0).split('.')[3]
                return r
        return None

    @ensure_path
    def _changed_paths(self):
        return [Info(path=join(self.sub, item.a_path),
                     type=item.change_type,
                     to=join(self.sub, self.default_if_none(item.rename_to)))
                for item in self.repo.commit().diff(self.head)]

    @ensure_path
    def diff_files(self, ref_branch):
        """
        gets changed file objects, relative to a branch
        diff = repo.git.diff('HEAD~1..HEAD', name_only=True)
        """
        diff = self.repo.git.diff(ref_branch, name_only=True)
        files = [f for f in diff.split('\n')]
        return files

    def list_added_files(self):
        return [i.path for i in self._changed_paths() if i.type == 'A']

    def list_deleted_files(self):
        return [i.path for i in self._changed_paths() if i.type == 'D']

    def list_changed_files(self):
        return [i.path for i in self._changed_paths() if i.type == 'M']

    def list_renamed_files(self):
        return [(i.path, i.to) for i in self._changed_paths() if i.type == 'R']

    def list_changed_types(self):
        return [i.path for i in self._changed_paths() if i.type == 'T']

    @property
    def branch(self):
        return self.repo.active_branch.name

    @property
    def message(self):
        return self.repo.commit().message

    @property
    def sha(self):
        return self.repo.commit().hexsha

    @property
    def author(self):
        return self.repo.commit().author.name

    @property
    def email(self):
        return self.repo.commit().author.email

    @property
    def head(self):
        if self._head is None:
            return 'HEAD~1'
        return self._head

    @head.setter
    def head(self, value):
        self._head = value

    @ensure_path
    def valid_files(self, files):
        valid = []
        invalid = []
        for f in files:
            if exists(f):
                valid.append(f)
            else:
                invalid.append(f)
        return (valid, invalid)

class Git(GitRepo):
    def __init__(self, config, head=None):
        super(Git, self).__init__(config, head)
        self.path = self.config['git_path']
        self.repo = Repo(self.path)

    def merged_branch(self):
        query = ['git', 'branch', '--contains', self.sha]
        branches = [f.strip().decode("utf-8")
                    for f in iter(self._subprocess(query))]
        if self.verbose:
            print(branches)
        if len(branches) == 1:
            print(branches[0][2:])
            return branches[0][2:]

        for branch in branches:
            if branch.startswith('*') or \
                    branch in ['master', 'staging', 'dev']:
                continue
            if branch.startswith('release'):
                return branch
        return None


class GitSVN(GitRepo):
    def __init__(self, config):
        super(GitSVN, self).__init__(config)
        self.path = self.config['gitsvn_path']
        self.repo = self._init_git()
        self.status = 0
        self.sub = 'src'

    def rel(self, name):
        if name.find(' ') == -1:
            return join('src', name)
        return join('src', '"{}"'.format(name))

    @ensure_path
    def _init_git(self):
        if self.config.get('gitsvn_path'):
            # print(folder)
            if self._expect('git svn info', 'URL', True):
                return Repo(self.path)
        raise GitSVNException('"{}" is not a '
                              'git svn repository'.format(self.path))

    def _remote(self):
        if self.repo is not None:
            rem = 'origin/' + self.branch
            if rem in self.repo.refs:
                return rem
        return None

    @ensure_path
    def push(self):
        if self._remote() is None and \
                self.branch != 'master':
            self._print_error('Cowardly refusing to push'
                              ' this local branch to svn')
            return False
        # if self._expect("git svn dcommit --dry-run", ['Committing']
        if self._run("git svn dcommit") == 0:
            return True
        self._print_error('Cloud not push to remote')
        return False

    @ensure_path
    def pull(self):
        if self._remote() is None and \
                self.branch != 'master':
            self._print_error('This branch does not track'
                              ' any svn branch')
            return False
        if self._run("git svn fetch") == 0:
            if self._expect("git svn rebase",
                            ["branch {0} is up to date".format(self.branch),
                             'no tracking']):
                return True
        self._print_error('Could not pull from remote')
        return False

    def req_from_branch(self, branch):
        issue = self.get_issue()
        if issue is not None:
            return 'Task XWALLET-{}'.format(issue)
        return 'Task XWALLET'

    @ensure_path
    def create_branch(self, branch):
        """
        substitui a _create_branch, para utilização aqui
        """
        if branch is not None:
            # release/18.04.1.123-hotfix9
            req = self.req_from_branch(branch)

            if self._expect('git svn branch -m "{0}" {1}'.format(req,
                                                                 branch),
                            ['Successfully', 'fatal']):
                if self.fetch():
                    if self.checkout_remote(branch):
                        return True
        return False

    @ensure_path
    def fetch(self):
        if self._run('git svn fetch') == 0:
            return True
        self._print_error('Could not fetch')
        return False

    @ensure_path
    def checkout_remote(self, branch):
        self.fetch()
        if self._expect('git checkout -b {0} origin/{1}'.format(branch,
                                                                branch),
                        [branch, 'fatal']):
            return True
        self._print_error('Could not checkout a remote branch "{}"'.format(branch))
        return False

    """
    @ensure_path
    def checkout_branch(self, branch):
       if branch is not None:
            try:
                status = self._expect('git checkout {0}'.format(branch),
                                      [branch, 'error'])
            except Exception:
                status = False
            if not status:

                # remote = '{}/branches/{}'.format(self.config['svn'], branch)
                return self.checkout_remote(branch)
            return status
        self._print_error('Cloud not checkout branch "{}"'.format(branch))
        return False
    """

    @ensure_path
    def checkout(self, branch):
        try:
            status = self._expect('git checkout {0}'.format(branch),
                                  [branch, 'Already'])
        except Exception as e:
            status = False

        if not status:
            self._print_error('Cloud not checkout a branch')
            status = self.checkout_remote(branch)
        else:
            self.fetch()
        return status

    @ensure_path
    def merge(self, branch):
        if branch is not None:
            current = self.branch
            if self.checkout(branch):
                if self.rebase():
                    if self.checkout(current):
                        if self._run('git merge --squash ' + branch) == 0:
                            msg = "merge {0} into {1}".format(branch, current)

                            return self._run(
                                    'git commit -m "{0}"'.format(msg)) == 0
                        self._print_error('Could not merge {0} into {1}'.format(branch, current))
        return False

    @ensure_path
    def rebase(self):
        return self._run('git svn rebase') == 0

    @ensure_path
    def info(self):
        return self._expect('git svn info', 'URL')

    @ensure_path
    def add_files(self, files):
        """
        new
        """
        names = ' '.join([self.rel(f) for f in files if exists((self.rel(f)))])
        if names:
            return self._run('git add ' + names)
        return 0

    @ensure_path
    def delete_files(self, files):
        """
        new
        """
        names = ' '.join([self.rel(f) for f in files if exists(self.rel(f))])
        if names:
            return self._run('git rm ' + names)
        return 0

    @ensure_path
    def rename_files(self, files):
        """
        new
        """
        fl = [item for item in files if exists(self.rel(item[0]))]
        for item in fl:
            self._run('git mv {} {}'.format(self.rel(item[0]),
                                            self.rel(item[1])))
        return 0

    def commit(self, message):
        """
        new
        """
        if message.lower().startswith('req ') or\
                message.lower().startswith('fix ') or\
                message.lower().startswith('task '):
            pass
        else:
            message = '{}. {}'.format(self.req_from_branch(self.branch),
                                      message)

        return self._run('git commit -m "{}"'.format(message))

    def list_remotes(self):
        args = ['git', 'branch', '-r']
        return [f.strip()[7:].decode("utf-8") for f in iter(self.default_(args))]


class Integrator():
    """
    https://www.digitalocean.com/community/tutorials/how-to-use-git-hooks-to-automate-development-and-deployment-tasks
    """
    def __init__(self, config):
        self.config = config
        self.copier = Copier(config)
        self.git = Git(config)
        self.gitsvn = GitSVN(config)
        self.branch = Branch(git=normalize_name(self.git.branch),
                             svn=self.gitsvn.branch)
        if self.config.get('verbose'):
            self.verbose = self.config['verbose']
        else:
            self.verbose = False

    def create_svn_branch(self, name):
        self.gitsvn.checkout('master')  # era checkout_branch
        self.gitsvn.fetch()
        self.gitsvn.rebase()
        return self.gitsvn.create_branch(normalize_name(self.git.branch))

    def _invoke_jenkins(self):
        if 'integration' in self.config:
            if self.config['integration']:
                try:
                    jenkins = self.config['jenkins']
                    if jenkins['branch'] == self.git.branch:
                        url = JENKINS_URL.format(jenkins['user'],
                                                 jenkins['authorization'],
                                                 jenkins['url'],
                                                 jenkins['job'],
                                                 jenkins['token'])
                        ignore_ssl = False
                        if 'ignore_ssl' in jenkins:
                            ignore_ssl = jenkins['ignore_ssl']

                        return call_jenkins(url,
                                            ignore_ssl,
                                            self.config['timeout'])
                except KeyError as e:
                    self._print_error('Incomplete Jenkins definitions')

        return True

    def checkout_svn_branch(self):
        remote = normalize_name(self.git.branch)
        branches = self.gitsvn.list_remotes()
        branches += ['master']
        # print(branches)
        # print('svn branch: ' + self.branch.svn + ' >' + self.branch.git)
        if remote in branches:
            if self.verbose:
                print('remote in branches ' + remote)
            self.gitsvn.fetch()
            self.gitsvn.checkout(remote)
            self._update_all()

        else:
            self.branch = Branch(git=self.git.branch,
                                 svn=normalize_name(self.git.branch))
            if self.verbose:
                print('create svn branch "{}"'.format(self.branch.svn))
            self.create_svn_branch(self.branch.svn)
            # copy all files diff from master
            # remote = 'origin/{}'.format(self.branch.svn)

            self.gitsvn.checkout_remote(remote)
            # copy all git branch modified files to svn
            # if git branch already merged in master, then does nothing
            self.git.head = 'master'
            self._update_all()

    def _same_branch(self):
        return normalize_name(self.branch.git) == self.branch.svn

    def _update_all(self):
        added = self.git.list_added_files()
        # files que podem ser apagados
        files = self.git.valid_files(added)

        # files que não existiam em HEAD~1
        deleted = self.git.list_deleted_files()

        modified = self.git.list_changed_files()
        renamed = self.git.list_renamed_files()

        try:
            changed = deleted + modified + files[0]
            if changed:
                self.copier.copy_files(changed)
                self.gitsvn.add_files(changed)
        except IOError as e:
            raise e

        try:
            if files[1]:
                self.gitsvn.delete_files(files[1])
            if renamed:
                self.gitsvn.rename_files(renamed)
        except IOError as e:
            raise e

    @list_files
    def _checkout(self):
        """
        called after checkout or clone
        """
        if sys.argv[3] == "1":  # its a branch
            # print('{} --> {}'.format(sys.argv[1], sys.argv[2]))
            self.checkout_svn_branch()
        else:
            # investigar que file ou files foram alterados
            # mas neste caso, os files originais já estarão no git-svn
            # ...a não ser que sejam versões anteriores ou de outros branches
            files = self.git.list_changed_files()
            self.copier.copy_files(files)
        return 0

    @list_files
    def _merge(self):
        """
        Called after a merge. Cannot abort
        """
        # found source branch... find a better way
        branch = self.git.merged_branch()
        if self.whitelisted_branch(branch):
            self._update_all()   # experimental
            self.gitsvn.merge(branch)
        return 0

    def _push(self):
        self.gitsvn.push()
        return 0

    def _rebase(self):
        """ stops rebasing """
        return 1

    @list_files
    def _commit(self):
        """
        Post commit. Cannot abort
        args: none
        """
        self._update_all()
        msg = self.git.message
        self.gitsvn.commit(msg)
        return 0

    def whitelisted_branch(self, branch_name=None):
        """
        Checks if a git branch should be transferred to SVN
        """
        if branch_name is None:
            branch_name = self.git.branch
        if self.config.get('branches'):
            for branch in self.config['branches']:
                if PurePath(branch_name).match(branch['name']):
                    if branch['ignore']:
                        return False
                    break
            else:
                return False
        return True

    def _validate(self):
        issue = self.git.get_issue()
        if issue is not None or\
                self.git.branch == 'master':
            return 0

        print('This branch does not conform with branch name conventions.')
        print('http://wiki.ptin.corppt.com/display/XWALLET/Git+e+gitsvn')
        return 127

    def run(self, command):
        """
        dispatcher
        """
        if not exists(expanduser(self.config['gitsvn_path'])):
            print('Please edit this config file: "{}"'
                  ', and adjust paths'.format(join(self.git.path, '.git/hooks/config.yml')))
            return 0

        switch = {'checkout': self._checkout,
                  'merge': self._merge,
                  'push': self._push,
                  'rebase': self._rebase,
                  'commit': self._commit,
                  'validate': self._validate
                  }
        # print(self.git.merged_branch())
        if not self.whitelisted_branch():
            if self.branch.git == 'staging' and \
                    command == 'push':
                self._invoke_jenkins()
            return 0

        if self._validate() != 0:
            return 1

        if not self._same_branch():
            self.checkout_svn_branch()

        if self._same_branch():
            return switch.get(command)()
        return 0


def main():
    """
    Expected to run inside the ".git" folder, as a git hook
    Supports client side hooks, and synchronizes a git repo
    with a git-svn repo, for svn continuous integration
    """
    config = configuration()
    config['git_path'] = src_dir()
    integrator = Integrator(config)
    command = sys.argv[1]

    sys.argv.remove(command)
    # print(sys.argv)
    return integrator.run(command)


if __name__ == "__main__":
    main()

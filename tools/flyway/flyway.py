#!/usr/bin/python3
# -*- coding: utf-8 -*-

from argparse import ArgumentParser, RawTextHelpFormatter
# from git import Repo
from os import listdir
from os.path import join, expanduser, basename, splitext, realpath, dirname
import MySQLdb
import datetime
import glob
import sys
import yaml

# from classes.database import Database
# from classes.myparser import MyParser

HELP = """
"""

HELP_NEW = """
Creates a new flyway version
"""

HELP_LIST = """
List existing flyways
"""

HELP_APPEND = """
Appends a new file to a existing flyway version
"""

HELP_TICKET = """
Reference ticket (ex: xwallet-123). Defaults to current git branch
"""

HELP_DESC = """
Component description on flyway file name
"""

HELP_SCHEMA = """
Database schema affected by this flyway. {0}
"""


HELP_RENAME = """
Renames an existing flyway version, identified by version (ex: 100_1)
"""


HELP_EPILOG = """
Examples:\n
    flyway --new schema description
    flyway --new schema description --ticket=<ticket>
    flyway --append <to_version> schema "description"
    flyway --rename 100.1 schema "new description"
    flyway --list <version> schema
    flyway --list 0 schema
"""

SQL_CREATE = """
CREATE TABLE `flyway` (`id` INT NOT NULL, `order` int NOT NULL, `schema` VARCHAR(30) NOT NULL, `description` VARCHAR(255) NOT NULL, `ticket` VARCHAR(64), PRIMARY KEY (`id`, `order`, `schema`));
"""


class MyParser(ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)


class Configurable(object):
    def __init__(self, config, environment=None):
        self.__config = config
        if environment is not None:
            self.config = config[environment]
        else:
            self.config = config

        @property
        def parent_config(self):
            return self.__config


class Database(Configurable):
    def __init__(self, config):
        Configurable.__init__(self, config)

        cfg = self.config['database']
        self.host = cfg['host']
        self.user = cfg['user']
        self.pwd = cfg['pass']
        self.schema = cfg['schema']
        self.db = MySQLdb.connect(self.host, self.user, self.pwd, self.schema)
        self.cursor = None

    def __del__(self):
        self.db.close()

    def insert(self, sql):
        if self.cursor is None:
            self.cursor = self.db.cursor()
        try:
            result = self.cursor.execute(sql)
            return result
        except MySQLdb.Error as e:
            raise e

    def get(self, sql):
        cursor = self.db.cursor()
        try:
            cursor.execute(sql)
            results = cursor.fetchall()
            return results
        except Exception as e:
            raise e

    def commit(self):
        if self.cursor is None:
            return
        try:
            self.db.commit()
        except MySQLdb.Error as e:
            self.db.rollback()
            raise e
        self.cursor.close()
        self.cursor = None


class Flyway:
    def __init__(self, config):
        self.database = Database(config)
        self.path = config['flyway']['basepath']
        self.flyways = config['flyway']['flyways']

    def _print_row(self, row):
        print('V{0}_{1}__{2} {3}'.format(*row))

    def _create_file(self, schema, row, ticket):
        filename = 'V{0}_{1}__{2}.sql'.format(*row)
        dst = join(join(self.flyways, schema), filename)
        now = datetime.datetime.now().strftime("%Y-%02m-%02d %02H:%02M")
        with open(dst, 'x') as f:
            f.write("-- Created at {0}, from branch {1}".format(
                now,
                # self.git_branch()))
                ticket))
        # self._print_row(row)
        print(dst)

    def git_branch(self):
        # repo = Repo(self.path)
        # return repo.active_branch
        pass

    def _sql_insert(self, schema, version, order, description, ticket):
        sql = ("insert into flyway (`schema`, id, `order`, description,"
               " ticket) values({0})")
        values = '"{0}",{1},"{2}","{3}","{4}"'.format(
            schema, version, order, description.replace(' ', '_'), ticket)
        return sql.format(values)

    def _list(self, schema, version=None):
        """
        id | order | schema| description | ticket
        """
        id = ''
        if version is not None:
            id = 'and id={0} '.format(version)
        sql = ('select id, `order`, description, ticket from flyway'
               ' where `schema`="{0}" {1}order by id, `order`')

        # print(sql.format(schema, id))
        return self.database.get(sql.format(schema, id))

    def print_list(self, schema, version=None):
        rows = self._list(schema, version)
        for row in rows:
            self._print_row(row)

    def _last(self, schema):
        """
        Finds the last row for a flyway schema
        """
        rows = self._list(schema)
        if len(rows) > 0:
            return rows[-1]
        return []

    def _last_version(self, schema, version):
        """
        Finds the last row for a flyway schema
        """
        rows = self._list(schema, version)
        if len(rows) > 0:
            return rows[-1]
        return []

    def _next(self, schema):
        """
        Returns next version number
        """
        row = self._last(schema)
        n = 1
        if len(row) > 0:
            self._print_row(row)
            n += int(row[0])
        return n

    def _next_sub(self, schema, version):
        """
        Returns next sub-version number
        """
        rows = self._list(schema, version)

        # for row in rows:
        #     self._print_row(row)
        n = 1
        if len(rows) > 0:
            n += int(rows[-1][1])
        return n

    def new(self, schema, description, ticket):
        """
        Creates a new flyway
        """
        try:
            n = self._next(schema)
            sql = self._sql_insert(schema, n, 1, description, ticket)
            self.database.insert(sql)

            self._create_file(schema, self._last(schema), ticket)
            self.database.commit()

        except Exception as e:
            raise e
        return (n, 1)

    def append(self, schema, version, description, ticket):
        """
        Appends a new flyway to a version
        """
        try:
            n = self._next_sub(schema, version)

            sql = self._sql_insert(schema, version, n, description, ticket)
            self.database.insert(sql)
            self._create_file(schema, self._last_version(schema, version), ticket)
            self.database.commit()

        except Exception as e:
            raise e

        return (version, n)

    def rename(self, schema, version, order, new_description):
        pass

    def delete(self, schema, version):
        pass

    def _insert_one(self, schema, name, branch):
        name = splitext(name)[0][1:]
        frags = name.split('__')
        ver = frags[0].split('_')
        if len(ver) == 1:
            ver.append('0')

        sql = self._sql_insert(schema, ver[0], ver[1], frags[1], branch)
        self.database.insert(sql)
        self._print_row([ver[0], ver[1], frags[1], schema])
        # print(sql)

    def _init(self, schema, path):
        # branch = self.git_branch()
        branch = "staging"
        files = glob.glob(path + "/*.sql")

        for f in sorted(files):
            self._insert_one(schema, basename(f), branch)
        self.database.commit()

    def _path(self, path):
        home = expanduser('~')
        return join(home, path)

    def init(self):
        """
        corre a dir dos flyways e mete todos na bd
        como fazer para aqueles que estão em branches particulares?
        """
        path = self.flyways
        self._init('sapopay', join(path, 'sapopay'))
        self._init('sapopayadmin', join(path, 'sapopayadmin'))


def get_arguments(config):
    parser = MyParser(description=HELP,
                      formatter_class=RawTextHelpFormatter,
                      epilog=HELP_EPILOG)

    group = parser.add_mutually_exclusive_group(required=True)

    group.add_argument("-n", "--new",
                       action='store_true',
                       help=HELP_NEW)

    group.add_argument("-a", "--append",
                       action="store",
                       type=int,
                       help=HELP_APPEND)

    group.add_argument("-r", "--rename",
                       action="store",
                       type=str,
                       help=HELP_RENAME)

    group.add_argument("-l", "--list",
                       help=HELP_LIST)

    parser.add_argument("-t", "--ticket",
                        action="store",
                        type=str,
                        help=HELP_TICKET)

    parser.add_argument("schema",
                        action='store',
                        metavar='schema',
                        type=str,
                        help=HELP_SCHEMA.format(*config['flyway']['schemas']))

    parser.add_argument("description",
                        action='store',
                        nargs='?',
                        metavar='description',
                        default='',
                        type=str,
                        help=HELP_DESC)

    args = parser.parse_args()

    if args.schema not in config['flyway']['schemas']:
        parser.error("'{0}' is not a known schema. Choices are [{1}]. ".format(
            args.schema,
            ", ".join(x for x in config['flyway']['schemas'])))

    if args.new is True or args.append is not None:
        if not args.description:
            parser.error("flyway description required")

    if args.ticket is None and args.list is None:
        parser.error("flyway ref ticket is required")

    print(repr(args))

    return args


def config_file():
    path = realpath(__file__)
    return join(dirname(path), "flyway.yml")


def main():
    with open(config_file(), 'r') as stream:
        try:
            config = yaml.load(stream)
            flyway = Flyway(config['dev'])

            args = get_arguments(config['dev'])

            # if args.ticket is None:
            #    args.ticket = flyway.git_branch()

            if args.new is True:
                flyway.new(args.schema,
                           args.description,
                           args.ticket)

            if args.append is not None:
                flyway.append(args.schema,
                                  args.append,
                                  args.description,
                                  args.ticket)

            if args.list is not None:
                if int(args.list) > 0:
                    flyway.print_list(args.schema, args.list)
                else:
                    flyway.print_list(args.schema)

        except yaml.YAMLError as e:
            raise e


if __name__ == "__main__":
    main()

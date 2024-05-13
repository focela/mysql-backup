# MySQL backup to AWS S3

This project provides Docker images to periodically back up a MySQL database to AWS S3, and to restore from the
backup as needed.

### 📦 Requirements

The Docker & Docker Compose system requirements are Linux Ubuntu as the OS (other operating systems are supported as
well), an absolute minimum 512MB RAM (2GB recommended)

In order to install docker Ubuntu, you will need to meet the following requirements:

- OS: Linux Ubuntu
- Memory: 512MB RAM (2GB Recommended)
- Disk: Sufficient amount to run the Docker containers you wish to use
- CPU: Dependant on the applications you wish to run in the containers

### 📋 Features

- Images are tagged by the major MySQL version supported: `8.0`, `8.1`, `8.2`, `8.3` or `8.4`.
- The `SCHEDULE` variable determines backup frequency. See go-cron schedules
  documentation [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules). Omit to run the backup
  immediately and then exit.
- If `PASSPHRASE` is provided, the backup will be encrypted using GPG.
- Run `docker exec <container name> sh backup.sh` to trigger a backup ad-hoc.
- If `BACKUP_KEEP_DAYS` is set, backups older than this many days will be deleted from S3.
- Set `S3_ENDPOINT` if you're using a non-AWS S3-compatible storage provider.

### 🔧 Installation

1. Install Docker and Docker-Compose

- [Docker Install documentation](https://docs.docker.com/install/)
- [Docker-Compose Install documentation](https://docs.docker.com/compose/install/)

2. Bring up your stack by running

```shell
git clone https://github.com/powaline/mysql-backup.git \
    && cd mysql-backup \
    && cp .env.example .env
```

3. Edit environment variable

```dotenv
# MySQL
MYSQL_USER=user
MYSQL_DATABASE=database
MYSQL_PASSWORD=password
MYSQL_ROOT_PASSWORD=rootPassword

# Backup
TZ=UTC
SCHEDULE=@weekly
BACKUP_KEEP_DAYS=7
PASSPHRASE=platonic-subdued-curvy-tweet-backroom
S3_BUCKET=my-s3-bucket
S3_REGION=us-east-1
S3_PREFIX=prefix
S3_ACCESS_KEY_ID=
S3_SECRET_ACCESS_KEY=
MYSQL_HOST=mysql
```

4. Start MySQL backup to AWS S3

```shell
docker-compose up -d
```

### 📝 Usage

Example `compose.yaml`

```yaml
version: "3.9"

services:
  mysql:
    container_name: mysql
    restart: always
    image: mysql:8.4
    environment:
      - MYSQL_USER=${MYSQL_USER:-user}
      - MYSQL_DATABASE=${MYSQL_DATABASE:-database}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD:-password}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootPassword}
    networks:
      - powaline

  backup:
    container_name: mysql-backup
    restart: always
    image: powaline/mysql-backup:8.4
    environment:
      - TZ=${TZ:-UTC}
      - SCHEDULE=${SCHEDULE:-@weekly}
      - BACKUP_KEEP_DAYS=${BACKUP_KEEP_DAYS:-7}
      - PASSPHRASE=${PASSPHRASE:-passphrase}
      - S3_REGION=${S3_REGION:-region}
      - S3_BUCKET=${S3_BUCKET:-bucket}
      - S3_PREFIX=${S3_PREFIX:-prefix}
      - S3_ACCESS_KEY_ID=${S3_ACCESS_KEY_ID:-key}
      - S3_SECRET_ACCESS_KEY=${S3_SECRET_ACCESS_KEY:-secret}
      - MYSQL_HOST=${MYSQL_HOST:-mysql}
    depends_on:
      - mysql
    networks:
      - powaline

networks:
  powaline:
    driver: bridge
    name: powaline
```

#### Restore

> **WARNING:** DATA LOSS! All database objects will be dropped and re-created.

### ... from latest backup

```sh
docker exec <container name> sh restore.sh
```

> **NOTE:** If your bucket has more than 1000 files, the latest may not be restored -- only one S3 `ls` command is used

### ... from specific backup

```sh
docker exec <container name> sh restore.sh <timestamp>
```

### 📨 Message

I hope you find this useful. If you have any questions, please create an issue.

### 🔐 Security

If you discover any security related issues, please email opensource@powaline.com instead of using the issue tracker.

### 📖 License

This software is released under the [BSD 3-Clause][link-license] License. Please see the [LICENSE](LICENSE) file
or https://powaline.com/license for more information.

### ✨ Contributors

Thanks go to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <td align="center" valign="top" width="14.28%">
    <a href="https://trants.me">
      <img src="https://avatars.githubusercontent.com/u/5866677?v=4?s=100" width="100px;" alt="Son Tran Thanh" />
      <br />
      <sub>
        <b>Son Tran Thanh</b>
      </sub>
    </a>
    <br />
    <a href="https://github.com/powaline/mysql-backup/commits?author=trants" title="Code">💻</a>
    <a href="https://github.com/powaline/mysql-backup/commits?author=trants" title="Documentation">📝</a>
  </td>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification.
Contributions of any kind welcome!

[link-license]: https://opensource.org/license/bsd-3-clause

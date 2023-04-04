/**
 * Script for uninstalling database.
 *
 * Usage:
 *   uninstall_db.js [OPTIONS]
 * Options:
 *    -d  uninstalls development database
 *    -force  force uninstallation, do not ask
 *
 * Version 1.3 2023-03-11 Vladyslav Potapenko
 */
const path = require('path');
const child = require('child_process');
require('dotenv').config({path: path.join(__dirname, '../.env')});
const readline = require('readline');

const yargs = require('yargs/yargs');
const {hideBin} = require('yargs/helpers');

const {argv} = yargs(hideBin(process.argv));

const cmd_db_pre = `su -l postgres -c "psql ${process.env.DB_NAME} -t -c \\"`;
const cmd_db_post = '\\""';

if (process.env.USER !== 'root') {
    console.log('This script should be run with root privileges ');
    return;
}

if (!process.env.DB_HOST) {
    console.log('There is no DB_HOST defined in .env file');
    return;
}

if (!process.env.DB_NAME) {
    console.log('There is no DB_NAME defined in .env file');
    return;
}

if (!process.env.DB_USER) {
    console.log('There is no DB_USER defined in .env file');
    return;
}

if (!process.env.DB_PASS) {
    console.log('There is no DB_PASS defined in .env file');
    return;
}

console.log(
    `This script will delete PostgreSQL ${process.env.DB_NAME} database `,
);

/**
 * Remove settings for database
 */
function cleanHBA() {
    // pg_hba.conf change
    const cmd_hba = `${cmd_db_pre}SHOW hba_file;${cmd_db_post}`;
    let hbaResp;
    try {
        hbaResp = child.execSync(cmd_hba).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during checking pg_hba file ', e.stderr.toString());
            return;
        }
        hbaResp = '';
    }
    console.log('pg_hba.conf file is at ', hbaResp.trim());
    // Checking if there is info inside this file
    const cmd_grep = `grep ${process.env.DB_NAME} ${hbaResp.trim()}`;
    let grepResp;
    try {
        grepResp = child.execSync(cmd_grep).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log(
                'Error during searching pg_hba file for database name ',
                e.stderr.toString(),
            );
            return;
        }
        grepResp = '';
    }
    if (grepResp.trim().indexOf(process.env.DB_NAME) === -1) {
        console.log('Nothing to change in pg_hba.conf file');
        return;
    }

    // Remove line with database configuration
    const cmd_sed = `sed -i '/host ${process.env.DB_NAME}*/d`;
    try {
        child.execSync(cmd_sed);
    } catch (e) {
        if (e.stderr.toString()) {
            console.log(
                'Error during setting pg_hba with new configuration ',
                e.stderr.toString(),
            );
            return;
        }
    }

    // Reload configuration
    const cmd_reload = `${cmd_db_pre}SELECT pg_reload_conf();${cmd_db_post}`;
    try {
        child.execSync(cmd_reload);
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during reloading configuration ', e.stderr.toString());
        }
    }
}

/**
 * Drop database and user after checking if exists
 */
function dropDatabase() {
    // Check if database exist
    const cmd_check = `su -l postgres -c "psql -l | grep '${process.env.DB_NAME}'"`;
    let dbResp;
    try {
        dbResp = child.execSync(cmd_check).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during checking database ', e.stderr.toString());
            return;
        }
        dbResp = '';
    }
    if (!dbResp.toUpperCase().indexOf(process.env.DB_NAME.toUpperCase())) {
        console.log('Database not found.');
        return;
    }

    // Drop database
    const cmd_db = `su -l postgres -c "dropdb ${process.env.DB_NAME}"`;
    try {
        child.execSync(cmd_db).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during dropping database ', e.stderr.toString());
            return;
        }
    }
    // Drop user
    const cmd_user = `su -l postgres -c "dropuser ${process.env.DB_USER}"`;
    try {
        child.execSync(cmd_user).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during dropping user ', e.stderr.toString());
            return;
        }
    }

    cleanHBA();
}

console.log('args check force ', argv.force);
if (!argv.force) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });
    console.log('Do you want to delete database [Y/N]? ');
    rl.input.on('keypress', (char, key) => {
        if (key === undefined) {
            console.log('Operation abort.');
            process.exit(1);
        } else {
            // console.log('Key [', key.name,']');
            if (key.name.toUpperCase() !== 'Y') {
                console.log('Operation abort.');
                process.exit(2);
            }
            dropDatabase();
            rl.close();
        }
    });
} else {
    dropDatabase();
}

/* eslint-disable no-console,@typescript-eslint/naming-convention,@typescript-eslint/no-unused-vars-experimental */
/**
 *  Update DB script using files with SQL patches.
 *  Have to be run with root privileges
 *
 * Changelog:
 * Version 1.3 2023-03-11 Vladyslav Potapenko
 */
const path = require('path');
const child = require('child_process');
require('dotenv').config({path: path.join(__dirname, '../.env')});
const {Pool} = require('pg');
const fs = require('fs');

const install_sql_dir = path.join(__dirname, '../data/init');
const update_sql_dir = path.join(__dirname, '../data/update');

console.log('Welcome to install and upgrade PostgreSQL database script.');

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

// Connecting with database
const cfg = {
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT,
};
const pool = new Pool(cfg);

const load_sql_file = async function (dir, file) {
    console.log(`${dir}/${file}`);
    if (!fs.existsSync(`${dir}/${file}`)) {
        console.log('File not exists');
        return true;
    }
    console.log(`${file} checking...`);
    const sql_check = 'SELECT 1 FROM updater_sql WHERE filename=$1';
    const {rows} = await pool.query(sql_check, [file]);
    if (rows.length > 0) {
        console.log(`${file} already executed`);
        return true;
    }
    // console.log('Executing ' + file + '...');
    const content = fs.readFileSync(`${dir}/${file}`);
    await pool.query(content.toString().trimStart());
    const sql_in =
        'INSERT INTO updater_sql (filename, content) VALUES ( $1, $2 ) ';
    await pool.query(sql_in, [file, content.toString().trimStart()]);
    console.log('Executed ');
    return true;
};

// Some global helper for PostgreSQL command execution
const cmd_db_pre = `su -l postgres -c "psql ${process.env.DB_NAME} -t -c \\"`;
const cmd_db_post = '\\""';

console.log('Update DB Script ');
console.log('Checking database...');

// Checking database
const cmd_check_db = `su -l postgres -c "psql -l | grep ${process.env.DB_NAME}" `;
let checkDb;
try {
    checkDb = child.execSync(cmd_check_db).toString();
} catch (e) {
    if (e.stderr.toString()) {
        console.log(`Error during checking database: ${e.stderr.toString()}`);
        return;
    }
    checkDb = '';
    // console.log('Database not found');
}

let newDb = false;
if (checkDb.trim().indexOf(process.env.DB_NAME) === -1) {
    // There are similar names, but not same
    console.log(
        `Database ${process.env.DB_NAME} not found. I will try to create it.`,
    );
    // Create user
    const cmd_user = `su -l postgres -c "createuser ${process.env.DB_USER} "`;
    let userResp;
    console.log('Create user');
    try {
        userResp = child.execSync(cmd_user).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during creating user ', e.stderr.toString());
            return;
        }
        userResp = '';
    }
    console.log('Create db');
    // Create database
    const cmd_db = `su -l postgres -c "createdb -E UTF8 -O ${process.env.DB_USER} ${process.env.DB_NAME}"`;
    let dbResp;
    try {
        dbResp = child.execSync(cmd_db).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during creating database ', e.stderr.toString());
            return;
        }
        dbResp = '';
    }
    // Set user password
    const cmd_user_pass = `${cmd_db_pre}ALTER USER ${process.env.DB_USER} WITH PASSWORD '${process.env.DB_PASS}';${cmd_db_post}`;
    // console.log('Set user password ', cmd_user_pass);
    let passResp;
    try {
        passResp = child.execSync(cmd_user_pass).toString();
    } catch (e) {
        if (e.stderr.toString()) {
            console.log('Error during set user password ', e.stderr.toString());
            return;
        }
        passResp = '';
    }
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
        console.log('Changing pg_hba.conf file');
        const cmd_sed = `sed -i '1i\host ${process.env.DB_NAME} ${
            process.env.DB_USER
        } 127.0.0.1/32 md5' ${hbaResp.trim()}`;
        let sedResp;
        try {
            sedResp = child.execSync(cmd_sed);
        } catch (e) {
            if (e.stderr.toString()) {
                console.log(
                    'Error during setting pg_hba with new configuration ',
                    e.stderr.toString(),
                );
                return;
            }
            sedResp = '';
        }
        // Reload configuration
        const cmd_reload = `${cmd_db_pre}SELECT pg_reload_conf();${cmd_db_post}`;
        let reloadResp;
        try {
            reloadResp = child.execSync(cmd_reload);
        } catch (e) {
            if (e.stderr.toString()) {
                console.log(
                    'Error during reloading configuration ',
                    e.stderr.toString(),
                );
                return;
            }
            reloadResp = '';
        }
    }
    newDb = true;
} // no database, creating.. done.

const cmd_ext = `${cmd_db_pre}CREATE EXTENSION IF NOT EXISTS pgcrypto;${cmd_db_post}`;
let extResp;
// console.log('ext: ', cmd_ext );
try {
    extResp = child.execSync(cmd_ext).toString();
} catch (e) {
    if (e.stderr.toString() && e.stderr.toString().indexOf('NOTICE:') === -1) {
        console.log('Error during creating extension ', e.stderr.toString());
        return;
    }
    extResp = '';
}
if (extResp.trim().indexOf('CREATE EXTENSION') === -1) {
    console.log('Error during creating pgcrypto ', extResp);
    return;
}

console.log('Checking updater_sql table.. ');

const sql_updater =
    'CREATE TABLE IF NOT EXISTS updater_sql ( \n' +
    '    filename    VARCHAR NOT NULL PRIMARY KEY,\n' +
    '    content     VARCHAR,\n' +
    '    installed   TIMESTAMP WITH TIME ZONE DEFAULT now()\n' +
    ');\n' +
    `GRANT ALL ON TABLE updater_sql TO ${process.env.DB_USER};\n` +
    "COMMENT ON TABLE updater_sql IS 'Files with SQL executed on database';";

(async () => {
    await pool.query(sql_updater);

    // Installation files first for new database
    if (newDb) {
        const script = `${install_sql_dir}/sql.data`;
        console.log(`New database, install script from ${script}`);
        if (!fs.existsSync(script)) {
            console.log("Can't find script file ", script);
            process.exit();
        }
        const content = fs.readFileSync(script);
        const files = content.toString().split('\r\n');
        for (let i = 0; i < files.length; i += 1) {
            if (!(await load_sql_file(install_sql_dir, files[i].trimStart()))) {
                console.log('Error. Close.');
                process.exit();
            }
        }
    } // new database

    // Load upgrade SQL files
    const files = await fs.promises.readdir(update_sql_dir);
    // console.log(JSON.stringify(files));
    for (let i = 0; i <= files.length - 1; i += 1) {
        if (files[i].toLowerCase().indexOf('.sql') === -1) {
            continue;
        }
        // console.log('Trying file ',files[i], ' @ ', update_sql_dir );
        const res = await load_sql_file(update_sql_dir, files[i].trimStart());
        if (!res) {
            console.log('Error. Close.');
            process.exit();
        }
    }
    pool.end();
})();

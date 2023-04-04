'use strict';
/**
 * Create new migration file
 * Usage:
 *    node .new.js filename
 */

const fs = require('fs');
const args = process.argv.slice(2);
const migrationName = args.join('_');
const files = fs.readdirSync(`${__dirname}/../sql`);
const timestamp = new Date().toISOString().replace(/[-T:.Z]/g, '').substring(0, 8);
const fileName = `${timestamp}_${migrationName}.sql`;
fs.writeFileSync(`${__dirname}/${fileName}`, getFileData(files, `${migrationName}`));

// Append line: ('20200110_fnc_license_list.sql');
fs.appendFileSync(`${__dirname}/../sql/_update_state.sql`, `,\n('${fileName}');`);
console.log('Please fix _update_state.sql file !');

//function to find and copy main function data
function getFileData(files, fileToFind) {
    const filteredFiles = files.filter((element) => {
        return element.includes(fileToFind);
    });
    if (filteredFiles.length > 0) {
        return fs.readFileSync(`${__dirname}/../sql/${filteredFiles[0]}`);
    } else {
        console.log('file not found, cannot copy automatically');
        return '';
    }
}

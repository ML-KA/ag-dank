// # setup:
// sudo npm install -g typescript
// npm install readline xlsx csv
// tsc parse.ts
// # run:
// node parse.js
const dont_output_false = true;
declare var require, process;
const fs = require('fs');
const readline = require('readline');
const xlsx = require('xlsx');
const csv = require('csv');
const sqlite = require('sqlite3').verbose();
const db = new sqlite.Database('../git/db_empty.sqlite');
const info = (fs.readFileSync("MAP_FILE.txt", 'utf8') as string)
	.split('\r\n')
	// ignore headers
	.slice(3)
	// split line by ≥1 spaces
	.map(line => line.split(/\s+/))
	// convert array [a,b,c] to object {a:a, b:b, c:c}
	.map(([variable, rec, start, end, format]) => ({ variable, rec, start, end, format }));

const varlev = xlsx.readFile('Variablen_Levels.xlsx');
// convert xlsx to csv because xlsx API sucks
const varlevcsv = xlsx.utils.sheet_to_csv(varlev.Sheets["VariablenLevels"]);

// maps from attribute id to attribute name according to xlsx
// e.g. "step2r1" to "Line - Fahrzeug 1" 
const attributenamemap = {};
// map from attribute to value number to value name according to pdf
// e.g. valnamemap["step2r1"]["2"] == "Sportline"
const valnamemap = {};

function cleanAttributeId(id: string) {
	return id.trim().replace(/^s(tep)?(\d)r\d(.*)$/, "s$1$2$3");
}

function mysql_real_escape_string (str) {
    return str.replace(/'/g, "''");
}

function cleanAttributeName(name: string) {
	name = name.trim();
	const match = name.match(/^(.*) - Fahrzeug \d$/);
	if(match) return match[1];
	else return name;
}
function cleanValueName(name: string) {
	return name.trim().replace(/\d+ ?€?$/, "").trim();
}
function parseMetadata(callback: () => void) {
	csv.parse(varlevcsv, { columns: ["attrid", , , , "attrname"] }, (err, data) => {
		data.forEach(line => attributenamemap[cleanAttributeId(line.attrid)] = cleanAttributeName(line.attrname));
		const valnames: { attr: string, val: string, valname: string }[] = [];
		csv.parse(fs.readFileSync('tabula-labels.csv', "utf8"), { columns: ["attr", "val", "valname"] }, (err, data) => {
			// remove pdf table headers
			data = data.filter(line =>
				!(line.attr.trim() == "Value" || line.valname.trim() == "Variable Values")
			);
			for (const line of data) {
				// remove spaces
				line.attr = cleanAttributeId(line.attr);
				line.val = line.val.trim();
				const last = valnames[valnames.length - 1];
				if (line.attr.length != 0 || line.val.length != 0) {
					if (line.attr.length == 0) line.attr = last.attr;
					valnames.push(line);
				} else {
					// if first two columns are empty, this is a continuation of the previous column
					last.valname += line.valname;
				}
			}

			for (const valname of valnames) {
				if (!valnamemap[valname.attr]) valnamemap[valname.attr] = {};
				const attr = cleanAttributeId(valname.attr);
				const name = cleanValueName(valname.valname);
				if (valnamemap[attr][valname.val] !== undefined && valnamemap[attr][valname.val] !== name) {
					process.stderr.write(`multiple definition: ${attr}=${valname.val} is already ${valnamemap[attr][valname.val]} but want to set to ${name}\n`);
				} else valnamemap[attr][valname.val] = name;
			}
			callback();
		});
	});
}

function prepare(stmt: string) {
	return function(...args:string[]) {
		args = args.map(mysql_real_escape_string);
		return stmt.replace(/\?/g, s => args.shift()) + ";\n";
	}
}

function parse_datline(line: string) {
	const data = {};
	for (const ele of info) data[ele.variable] = line.substring(+ele.start - 1, +ele.end);
	return data;
}

function insertMetadataIntoDatabase() {
	const stmt = prepare(`insert into feature_name values ('?', '?')`);
	const stmt2 = prepare(`insert into value_name values ('?', ?, '?')`);
	for(let attr of Object.keys(attributenamemap)) {
		const attrclean = cleanAttributeId(attr);
		process.stdout.write(stmt(attrclean, attributenamemap[attr]));
		if(valnamemap[attr]) for(let val of Object.keys(valnamemap[attr])) {
			process.stdout.write(stmt2(attrclean, val, valnamemap[attr][val]));
		}
	}
	parseData();
}

function parseData() {
	// read line by line
	const rl = readline.createInterface({ input: fs.createReadStream('konfigurator_small.dat') });
	let person_id = 0;
	rl.on('line', line => {
		person_id++;
		const data = parse_datline(line);
		process.stdout.write(prepare(`insert into person_budget values (?, ?)`)(""+person_id, data["step1_budget"]));
		// replace attribute ids and value ids with their names
		const cars = [{},{},{},{}];
		delete data["respid"];
		delete data["step1_budget"];
		for (let attr in data) {
			if (attr === "") {
				//TODO why does this happen?
				continue;
			}
			let carx = attr.match(/^s(?:tep)?\dr(\d)/);
			if(attr === "budget_F") carx = [,"1"];
			if (carx) {
				// belongs to a specific selected configuration, output in "carN" sub-object
				const carnum = +carx[1];
				const car_id = person_id * 4 + carnum;
				let val = +data[attr].trim();
				attr = cleanAttributeId(attr);
				const attrvalnames = valnamemap[attr];
				if(attr.match(/^s7/)) {
					if(dont_output_false && val === 0) {
						continue;
					}
				}
				process.stdout.write(prepare(`insert into feature values (?, '?', ?)`)(""+car_id, attr, ""+val));
			} else throw Error(`what is attribute ${attr}?`);
		}
		process.stdout.write('\n');
	});
}


parseMetadata(insertMetadataIntoDatabase);
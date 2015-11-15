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

function cleanAttributeName(name: string) {
	name = name.trim();
	const match = name.match(/^(.*) - Fahrzeug \d$/);
	if(match) return match[1];
	else return name;
}
function parseMetadata(callback: () => void) {
	csv.parse(varlevcsv, { columns: ["attrid", , , , "attrname"] }, (err, data) => {
		data.forEach(line => attributenamemap[line.attrid.trim()] = cleanAttributeName(line.attrname));
		const valnames: { attr: string, val: string, valname: string }[] = [];
		csv.parse(fs.readFileSync('tabula-labels.csv', "utf8"), { columns: ["attr", "val", "valname"] }, (err, data) => {
			// remove pdf table headers
			data = data.filter(line =>
				!(line.attr.trim() == "Value" || line.valname.trim() == "Variable Values")
			);
			for (const line of data) {
				// remove spaces
				line.attr = line.attr.trim();
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
				if (valnamemap[valname.attr][valname.val] !== undefined)
					throw Error(`multiple definition: ${valname.attr}=${valname.val} is already ${valnamemap[valname.attr][valname.val]} but want to set to ${valname.valname}`);
				valnamemap[valname.attr][valname.val] = valname.valname;
			}
			callback();
		});
	});
}

function parse_datline(line: string) {
	const data = {};
	for (const ele of info) data[ele.variable] = line.substring(+ele.start - 1, +ele.end);
	return data;
}
function parseData() {
	// read line by line
	const rl = readline.createInterface({ input: fs.createReadStream('konfigurator_small.dat') })
	rl.on('line', line => {
		const data = parse_datline(line);
		
		// replace attribute ids and value ids with their names
		const nicedata = {};
		for (let attr in data) {
			let target = nicedata;
			const carx = attr.match(/^s(?:tep)?\dr(\d)/);
			if (carx) {
				// belongs to a specific selected configuration, output in "carN" sub-object
				const carnum = "car" + carx[1];
				nicedata[carnum] = nicedata[carnum] || {};
				target = nicedata[carnum];
				// remove "- Fahrzeug n" suffix
				const m = attr.match(/^(.*) - Fahrzeug \d$/);
				if(m) attr = m[1];
			}
			if (attr === "") {
				//TODO why does this happen?
				continue;
			}
			const val = data[attr].trim();
			const attrname = attributenamemap[attr];
			if (!attrname) throw `can't name '${attr}'`;
			const attrvalnames = valnamemap[attr];
			if (!attrvalnames) {
				if(attr === "respid") target[attrname] = val;
				else if(["budget_F","step1_budget","step1r1"].indexOf(attr) >= 0) target[attrname] = +val; // to number
				else if(attr.match(/^s7r/)) {
					if(val !== "0" || !dont_output_false) {
						target[attrname] = !! +val; // to boolean
					}
				} else throw Error(`could not find value names for attr ${attr}=${val}`);
				continue;
			}
			const valname = attrvalnames[val];
			if(!valname) {
				if(val == "0") {
					target[attrname] = null; // car n not configured
				}
				else throw Error(`don't know ${attr}=${val}`);// in ${JSON.stringify(data)}`);
			}
			target[attrname] = valname;
		}
		process.stdout.write(JSON.stringify(nicedata));
		process.stdout.write('\n');
	});
}


parseMetadata(parseData);
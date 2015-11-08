PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE `feature` (
	`car_id`	TEXT,
	`feature_id`	TEXT,
	`value_id`	INTEGER,
	PRIMARY KEY(car_id,feature_id)
);
CREATE TABLE `feature_name` (
	`feature_id`	TEXT,
	`name`	TEXT,
	PRIMARY KEY(feature_id)
);
CREATE TABLE "person_budget" (
	`person_id`	INTEGER,
	`budget`	INTEGER,
	PRIMARY KEY(person_id)
);
CREATE TABLE "person_car" (
	`car_id`	INTEGER,
	`person_id`	INTEGER,
	PRIMARY KEY(car_id)
);
CREATE TABLE "value_name" (
	`feature_id`	TEXT,
	`value_id`	INTEGER,
	`name`	TEXT,
	PRIMARY KEY(feature_id,value_id)
);
COMMIT;

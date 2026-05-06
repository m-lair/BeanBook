#!/usr/bin/env node

const fs = require("fs");

const path = process.argv[2] || "BeanBook/Resources/beans_catalog.json";
const required = [
  "id",
  "roaster",
  "name",
  "origin",
  "process",
  "roastLevel",
  "tastingNotes",
  "description",
  "roasterURL",
];
const processes = new Set(["washed", "natural", "honey", "anaerobic", "decaf", "other"]);
const roastLevels = new Set(["light", "mediumLight", "medium", "mediumDark", "dark"]);

let beans;
try {
  beans = JSON.parse(fs.readFileSync(path, "utf8"));
} catch (error) {
  console.error(`Failed to parse ${path}: ${error.message}`);
  process.exit(1);
}

const issues = [];
const ids = new Map();

if (!Array.isArray(beans)) {
  issues.push("catalog root must be an array");
} else {
  beans.forEach((bean, index) => {
    for (const key of required) {
      if (bean[key] === undefined || bean[key] === null || bean[key] === "") {
        issues.push(`${index}: missing ${key}`);
      }
    }

    if (ids.has(bean.id)) {
      issues.push(`${index}: duplicate id ${bean.id}; first seen at ${ids.get(bean.id)}`);
    } else {
      ids.set(bean.id, index);
    }

    if (!processes.has(bean.process)) {
      issues.push(`${index}: invalid process ${bean.process}`);
    }

    if (!roastLevels.has(bean.roastLevel)) {
      issues.push(`${index}: invalid roastLevel ${bean.roastLevel}`);
    }

    if (!Array.isArray(bean.tastingNotes) || bean.tastingNotes.length === 0) {
      issues.push(`${index}: tastingNotes must be a non-empty array`);
    }

    if (typeof bean.roasterURL !== "string" || !/^https?:\/\//.test(bean.roasterURL)) {
      issues.push(`${index}: roasterURL must be an http(s) URL`);
    }

    for (const key of ["roasterLat", "roasterLng"]) {
      if (bean[key] !== undefined && bean[key] !== null && typeof bean[key] !== "number") {
        issues.push(`${index}: ${key} must be a number when present`);
      }
    }
  });
}

if (issues.length > 0) {
  console.error(issues.join("\n"));
  process.exit(1);
}

console.log(`Catalog validation passed: ${beans.length} beans.`);

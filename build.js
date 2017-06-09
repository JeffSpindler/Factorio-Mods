const fs = require('fs');
const path = require('path');
const exec = require('child_process').exec;
const AdmZip = require('adm-zip');
const readdirp = require('readdirp');

function main() {
  if (!process.argv[2]) {
    return console.log('Please supply a directory name as argument');
  }

  let mod = path.join(__dirname, process.argv[2]);
  fs.stat(mod, (err, x) => {
    if (err) return console.log(`The directory ${mod} does not exist`);
    if (!x.isDirectory()) return console.log(`${mod} is not a directory`);
    build(mod);
  });
}

async function build(mod) {
  console.log(`Building ${mod}`);
  const info = JSON.parse(fs.readFileSync(path.join(mod, 'info.json'), 'utf8'));
  const dir = path.resolve(`build`);
  const filename = `${info.name}_${info.version}`;
  await createBuildDirectory(dir);
  await zip(mod, dir, filename);
  // process.exit();
}

async function createBuildDirectory() {
  await promisify(fs.mkdir, path.join(__dirname, 'build')).catch((e) => {});
  // await promisify(fs.mkdir, dir).catch((e) => {});
}

function promisify(fn, ...args) {
  return new Promise((resolve, reject) => {
    fn(...args, (err, ...result) => {
      if (err) reject(err);
      else resolve(...result);
    });
  });
}

function zip(directory, destination, filename) {
  return new Promise((resolve, reject) => {
    console.log(`Zipping ${directory}...`);
    var zip = new AdmZip();
    let progress = [];
    readdirp({root: directory}).on('data', async (file) => {
      progress.push(promisify(fs.readFile, file.fullPath).then(content => {
        let zippath = filename + '/' + file.path.replace(/\\/g, '/');
        zip.addFile(zippath, content, '', 0644 << 16);
        console.log(`- ${file.path} [${Math.round(content.length / 102.4)/10}kb] added`);
      }));
    }).on('end', () => {
      Promise.all(progress).then(() => {
        zip.writeZip(path.resolve(destination, `${filename}.zip`), () => {
          console.log('test');
        });
        console.log(`Done: ${path.resolve(destination, `${filename}.zip`)}`);
        resolve();
      });
    });
  });
}

main();
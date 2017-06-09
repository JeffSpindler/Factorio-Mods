const fs = require('fs');
const path = require('path');
const readdirp = require('readdirp');

function readdir(root, opts, handler) {
  if (typeof opts === 'function') {
    handler = opts;
    opts = {};
  }
  opts = Object.assign(opts, {root});
  return new Promise((resolve, reject) => {
    let actions = [];
    readdirp(opts).on('data', (file) => {
      actions.push(handler(file));
    }).on('error', (reason) => {
      reject(reason);
    }).on('end', () => {
      resolve(Promise.all(actions));
    });
  })
}

async function watch(mod) { 
  const modDir = getModDirectory();
  const info = JSON.parse(fs.readFileSync(path.join(mod, 'info.json'), 'utf8'));
  const destination = path.join(modDir, `${info.name}_${info.version}`);

  await promisify(fs.mkdir, destination).catch(() => {});

  console.log('Clearing old files...');
  await clearDirectory(destination);
  console.log('Copying new files...');
  await copyDirectory(mod, destination);

  console.log(`Watching ${mod}`);

  // Watch main directory
  watchDirectory(mod, mod, destination);
  // Watch sub directories (fs.watch is buggy in this)
  readdirp({root: mod, entryType: 'directories'}).on('data', async (file) => {
    watchDirectory(file.fullPath, mod, destination);
  }).on('error', (reason) => {
    reject(reason);
  }).on('end', () => {
    console.log(`Now watching all files in ${mod}`);
  });
}

function watchDirectory(dir, source, destination) {
  fs.watch(dir, (type, file) => {
    console.log('watcher', type, file);
    let relativeDir = path.relative(source, dir);
    let from = path.resolve(dir, file);
    let to = path.resolve(destination, relativeDir, file);
    console.log('-', from);
    console.log('-', to);
    fs.createReadStream(from).pipe(fs.createWriteStream(to));
  });
}

function copyDirectory(from, to) {
  return readdir(from, {entryType: 'both'}, (file) => {
    let dest = path.resolve(to, path.relative(from, file.fullPath));
    if (file.stat.isDirectory()) {
      return promisify(fs.mkdir, dest).catch(() => {});
    }
    fs.createReadStream(file.fullPath).pipe(fs.createWriteStream(dest));
  });
}

function clearDirectory(directory) {
  return new Promise((resolve, reject) => {
    let files = [];
    let folders = [];
    readdirp({root: directory, entryType: 'both'}).on('data', async (file) => {
      if (file.stat.isDirectory()) {
        folders.push(file.fullPath);
      } else {
        files.push(file.fullPath);
      }
    }).on('error', (reason) => {
      reject(reason);
    }).on('end', () => {
      folders.sort((a, b) => b.length - a.length);
      resolve(Promise.all(files.map(path => promisify(fs.unlink, path))).then(() => {
        return Promise.all(folders.map(path => promisify(fs.rmdir, path)));
      }));
    });
  });
}

function main() {
  if (!getModDirectory()) {
    return console.log('Failed to find mod directory');
  }
  if (!process.argv[2]) {
    return console.log('Please supply a mod directory name as argument');
  }

  let mod = path.join(__dirname, process.argv[2]);
  fs.stat(mod, (err, x) => {
    if (err) return console.log(`The directory ${mod} does not exist`);
    if (!x.isDirectory()) return console.log(`${mod} is not a directory`);
    watch(mod).catch(reason => {
      console.log(reason);
    });
  });
}

function getModDirectory() {
  if (process.argv[3]) {
    let dir = path.resolve(process.argv[3]);
    let stats = fs.statSync(dir);
    if (stats && stats.isDirectory()) return dir;
    else return null;
  }
  if (process.platform == 'win32' && process.env.APPDATA) {
    return path.resolve(process.env.APPDATA, 'Factorio/mods');
  } else if (process.env.HOME) {
    return path.resolve(process.env.HOME, '.factorio/mods');
  }
  return null;
}

function promisify(fn, ...args) {
  return new Promise((resolve, reject) => {
    fn(...args, (err, ...result) => {
      if (err) reject(err);
      else resolve(...result);
    });
  });
}

main();
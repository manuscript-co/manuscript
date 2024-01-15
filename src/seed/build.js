import * as esbuild from 'esbuild'

class /*fun with*/ Flags {
  constructor() {
    this.optimize = 'Debug';
    this.outDir = 'build';
  }
  get isRelease() {
    return this.optimize !== 'Debug';
  }
  static regex = /-D(\w+)\s*=\s*(\S+)/g;
  static parse() {
    const args = new Flags();
    let result;
    const str = process.argv.join(' ');
    while ((result = Flags.regex.exec(str)) !== null) {
      args[result[1]] = result[2];
    }
    return args;
  }
};

const args = Flags.parse();
await esbuild.build({
  entryPoints: ['seed.ts'],
  bundle: true,
  minify: args.isRelease,
  sourcemap: args.isRelease ? false : 'linked',
  outdir: args.outDir,
  external: ['./jrt'],
  jsxDev: false,
});
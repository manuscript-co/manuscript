import {transform} from "sucrase";
import { getCode } from "./jrt";

const code = '1+1'; //getCode();
const tcode = transform(
    code, {transforms: ["typescript", "imports"]}
).code;

new Function(tcode).call(this);
import {transform} from "sucrase";
const code = getCode();
const compiledCode = transform(
        code, {transforms: ["typescript", "imports"]}
    ).code;
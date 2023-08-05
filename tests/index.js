function jitMe(y){
    arr[y] += obj.sum;
    obj.sum += y
}

let arr = [];
let obj = {sum: 0}

for(let y = 0; y < 1000; y++){
    jitMe(y)
}
42
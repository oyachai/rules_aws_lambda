import {blah} from "./lib/hello_lib";
import * as _ from "lodash";

export function handler(event: any, context: any) {
    blah();
}

handler(0, 0);

module lublinsql::error;

import lublinsql::position;
import std::collections::list;

struct Error {
    String value;
    PositionVector position;
}

List{Error} errors;

fn void initErrors() {
    errors.init(mem);
}

fn void createError(String value, PositionVector position) {
    Error err = {
        .value = value,
        .position = position
    };

    errors.push(err);
}
module lublinsql::parser;

import lublinsql::error;
import lublinsql::position;

struct Resulter {
    bool has_error;
    Node value;
}

fn Resulter makeSuccessResult(Node node) {
    Resulter res = {
        .has_error = false,
        .value = node
    };
    return res;
}

fn Resulter makeFailureResult(String message, PositionVector position) {
    error::createError(message, position);
    Resulter res = {
        .has_error = true,
        .value = (Node)null
    };
    return res;
}

fn bool Resulter.isError(Resulter* this) {
    return this.has_error;
}
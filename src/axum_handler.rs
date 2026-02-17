use axum::extract::{Path, Query};
use axum::Json;
use lambda_http::http::StatusCode;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

#[derive(Deserialize, Serialize)]
pub struct Params {
    first: Option<String>,
    second: Option<String>,
}

pub async fn get_name(Path(name): Path<String>) -> Json<Value> {
    Json(json!({ "msg": name }))
}

pub async fn get_parameters(Query(params): Query<Params>) -> Json<Value> {
    Json(json!(params))
}

pub async fn health_check() -> (StatusCode, String) {
    let health = true;
    match health {
        true => (StatusCode::OK, "healthy".to_string()),
        false => (StatusCode::INTERNAL_SERVER_ERROR, "unhealthy".to_string()),
    }
}
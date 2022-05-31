pub fn sanitize(input: impl AsRef<str>) -> String {
    ammonia::clean(input.as_ref())
}

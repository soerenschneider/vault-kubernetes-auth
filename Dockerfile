FROM golang:1.19.4 AS build

WORKDIR /src
COPY ./go.mod ./go.sum ./
RUN go mod download

COPY ./ ./
ENV CGO_ENABLED=0
RUN go mod download
RUN CGO_ENABLED=0 go build -o /vault-kubernetes-auth


FROM gcr.io/distroless/static AS final

LABEL maintainer="soerenschneider"
USER nonroot:nonroot
COPY --from=build --chown=nonroot:nonroot /vault-kubernetes-auth /vault-kubernetes-auth

ENTRYPOINT ["/vault-kubernetes-auth"]

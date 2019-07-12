#!/usr/bin/env puma

threads_count = ENV.fetch('PUMA_THREADS') { 5 }.to_i
threads threads_count, threads_count

port ENV.fetch('PORT') { 4567 }
workers ENV.fetch('WORKERS') { 1 }.to_i

environment ENV.fetch("RACK_ENV") { "production" }

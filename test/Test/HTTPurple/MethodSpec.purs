module Test.HTTPurple.MethodSpec where

import Prelude

import HTTPurple.Method (Method(Get, Post, Put, Delete, Head, Connect, Options, Trace, Patch, Query), read)
import Test.HTTPurple.TestHelpers (Test, mockRequest, (?=))
import Test.Spec (describe, it)

showSpec :: Test
showSpec =
  describe "show" do
    describe "with a Get" do
      it "is 'Get'" do
        show Get ?= "Get"
    describe "with a Post" do
      it "is 'Post'" do
        show Post ?= "Post"
    describe "with a Put" do
      it "is 'Put'" do
        show Put ?= "Put"
    describe "with a Delete" do
      it "is 'Delete'" do
        show Delete ?= "Delete"
    describe "with a Head" do
      it "is 'Head'" do
        show Head ?= "Head"
    describe "with a Connect" do
      it "is 'Connect'" do
        show Connect ?= "Connect"
    describe "with a Options" do
      it "is 'Options'" do
        show Options ?= "Options"
    describe "with a Trace" do
      it "is 'Trace'" do
        show Trace ?= "Trace"
    describe "with a Patch" do
      it "is 'Patch'" do
        show Patch ?= "Patch"
    describe "with a Query" do
      it "is 'Query'" do
        show Query ?= "Query"

readSpec :: Test
readSpec =
  describe "read" do
    describe "with a 'GET' Request" do
      it "is Get" do
        request <- mockRequest "" "GET" "" "" []
        read request ?= Get
    describe "with a 'QUERY' Request" do
      it "is Query" do
        request <- mockRequest "" "QUERY" "" "" []
        read request ?= Query
    describe "with a lowercase 'query' Request" do
      it "is Get, since HTTP method tokens are case-sensitive" do
        request <- mockRequest "" "query" "" "" []
        read request ?= Get

methodSpec :: Test
methodSpec =
  describe "Method" do
    showSpec
    readSpec

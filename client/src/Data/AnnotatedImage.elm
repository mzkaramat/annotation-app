-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module Data.AnnotatedImage exposing
    ( AnnotatedImage
    , AnnotatedImageUpdate
    , Status(..)
    , encode
    , fromRaw
    , hasAnnotations
    , reset
    )

import Data.Annotation as Annotation exposing (Annotation)
import Data.Image as Image exposing (Image)
import Data.Pointer as Pointer
import Data.RawImage as RawImage exposing (RawImage)
import Data.Tool as Tool exposing (Tool)
import Json.Encode as Encode exposing (Value)
import Packages.Zipper as Zipper exposing (Zipper)



-- TYPES #############################################################


type alias AnnotatedImage =
    { name : String
    , status : Status
    }


type Status
    = Loading
    | Loaded Image
    | LoadedWithAnnotations Image (Zipper AnnotationWithId)
    | LoadingError String


type alias AnnotationWithId =
    { id : Int
    , classId : Int
    , annotation : Annotation
    }



-- FUNCTIONS #########################################################


reset : AnnotatedImage -> AnnotatedImage
reset annotatedImage =
    case annotatedImage.status of
        LoadedWithAnnotations img _ ->
            { annotatedImage | status = Loaded img }

        _ ->
            annotatedImage


hasAnnotations : AnnotatedImage -> Bool
hasAnnotations annotatedImage =
    case annotatedImage.status of
        LoadedWithAnnotations _ _ ->
            True

        _ ->
            False


updateCurrentWith : (Annotation -> Annotation) -> AnnotatedImage -> AnnotatedImage
updateCurrentWith f annotatedImage =
    case annotatedImage.status of
        LoadedWithAnnotations img zipper ->
            let
                newStatus =
                    LoadedWithAnnotations img (Zipper.updateC (updateAnnotation f) zipper)
            in
            { annotatedImage | status = newStatus }

        _ ->
            annotatedImage


updateAnnotation : (Annotation -> Annotation) -> { record | annotation : Annotation } -> { record | annotation : Annotation }
updateAnnotation f record =
    { record | annotation = f record.annotation }



-- Pointer stuff


addAnnotationsIndicator type_ ( list, dragState, hasChanged ) =
    Debug.todo "to remove"


type alias AnnotatedImageUpdate =
    { newAnnotatedImage : AnnotatedImage
    , newDragState : Pointer.DragState
    , hasAnnotations : Bool
    , hasChanged : Bool
    }



-- Conversion from raw image


fromRaw : Zipper Tool -> RawImage -> AnnotatedImage
fromRaw tools { id, name, status } =
    let
        annotatedStatus =
            case status of
                RawImage.Loading ->
                    Loading

                RawImage.LoadingError error ->
                    LoadingError error

                RawImage.Loaded image ->
                    Loaded image
    in
    { name = name, status = annotatedStatus }



-- Encoders


encode : AnnotatedImage -> Value
encode { name, status } =
    case status of
        LoadedWithAnnotations img zipper ->
            Encode.object
                [ ( "image", Encode.string name )
                , ( "size", Encode.list Encode.int [ img.width, img.height ] )
                , ( "annotations", Encode.list encodeAnnotationWithId (Zipper.getAll zipper) )
                ]

        _ ->
            Encode.object
                [ ( "image", Encode.string name )
                , ( "annotations", Encode.null )
                ]


encodeAnnotationWithId : AnnotationWithId -> Value
encodeAnnotationWithId { id, classId, annotation } =
    Encode.object
        [ ( "classId", Encode.int classId )
        , ( "annotation", Annotation.encode annotation )
        ]

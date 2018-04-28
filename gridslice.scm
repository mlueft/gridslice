;
; This function slices a pictures in parts of width and height and saves each part
; as a png file with a gives prefix in a gives folder.
;
; file name format: [path]\[prefix]_[line]_[column].png
;

;
;	main function 
;
(define (script-fu-gridslice image drawable xspace yspace folder prefix merge)

	; if set image will be duplicated and visible layers will be merged.
	; original image is untouched.
	(if ( = merge TRUE)
		(let*	
			(
				(new-image (car (gimp-image-duplicate image)))
				(layers (gimp-image-get-layers new-image))
				(num-layers (car layers))
				(layer-count (- num-layers 1))
				(layer-array (cadr layers))

			)

			; removing all unvisible layers in duplicated image
			; i am not sure if it is really needed to remove al invisible layers
			; first tests worked correctly without removing it.
			; to get sure the script is working as expected i will remove them.
			(while (>= layer-count 0)
				(let* 
					((layer (aref layer-array layer-count)))

					(if (= (car (gimp-drawable-get-visible layer)) FALSE)
						(gimp-image-remove-layer new-image layer)
					)

					(set! layer-count (- layer-count 1))
				)			
			)

			(gimp-image-merge-visible-layers new-image 1)
			(iterate-image new-image (car (gimp-image-get-active-drawable new-image)) 0 0 xspace yspace folder prefix 1 1 )
			(gimp-image-delete new-image)
		)
	)
	
	(if ( = merge FALSE)
		; calls iterate-image function
		(iterate-image image drawable 0 0 xspace yspace folder prefix 1 1 )
	)
	
	; outputs the finish message
	(gimp-message "finish!")
)


;
;	iterates the image recursively and saves each part of the image
;
(define (iterate-image image drawable x y width height folder prefix line column )
	
;	(gimp-message (string-append (number->string x) "x" (number->string x) ":" (number->string width) "x" (number->string height)))
	
	(let* 
		(
			; creates the full file name
; old names		
			(name (string-append folder "/" prefix "_" (number->string line) "_" (number->string column) ".png"))			
; new names
;			(name (string-append folder "/" prefix "_" (format line) "_" (format column) ".png"))

		)
		
		; calls the save function
		(safe-part image drawable x y width height name)
		
		; increases the x cordinate of the part to be saved next
		(set! x (+ x width))
		
		; increases the collumn variable - used in file name
		(set! column (+ column 1))

		; checks if x is higher than the image width
		; if true start next line
		(if (>= x (car (gimp-image-width image)))
			(begin
				(set! column 1)
				(set! y (+ y height))
				(set! line (+ line 1))
				(set! x 0)
			)
		)

		; continues saving parts till y coordinate is smaller than image height
		(if (< y (car (gimp-image-height image)))
			(iterate-image image drawable x y width height folder prefix line column)
		)

	)
)

;
; format a number to string
;
(define (format mynumber)
		
	(let*	(
			(result "")
		)
		(if (= 1 (string-length (number->string mynumber)))
			(set! result (string-append "000" (number->string mynumber)) )		
			(if (= 2 (string-length (number->string mynumber)))
				(set! result (string-append "00" (number->string mynumber)) )
				(if (= 3 (string-length (number->string mynumber)))
					(set! result (string-append "0" (number->string mynumber)) )
					(
						(if (= 4 (string-length (number->string mynumber)))
							(set! result (string-append "" (number->string mynumber)) )
							(
								(set! result (number->string mynumber) )
							)
						)
					)
				)
			)
		)
	)
)

;
; saves a part of the image
;
(define (safe-part image drawable x y width height name)

	(let* 
		((newimage 0))
		(gimp-selection-none image)
		(gimp-rect-select image x y width height 0 FALSE 0)
		(gimp-edit-copy-visible image)
		(gimp-edit-copy drawable)
		(set! newimage (car (gimp-edit-paste-as-new)))
		(file-png-save-defaults 
			1
			newimage 
			(car (gimp-image-get-active-drawable newimage))
			name
			name
		)
	)
)


;
;	registers the script in gimp
;
(script-fu-register "script-fu-gridslice"
		    _"_Gridslice"
		    _"slices the picture and saves the parts as PNGs."
		    "Michael Lueftenegger"
		    "2008,2009, Michael Lueftenegger"
		    "Feb 08, 2009"
		    "*"
		    
		    SF-IMAGE "Image" 0
		    SF-DRAWABLE "Drawable" 0
		    
		    SF-VALUE "x space" "30"
		    SF-VALUE "y space" "30"
		    SF-STRING "folder" "C:/temp"
		    SF-STRING "file name prefix" "tile"
		    SF-TOGGLE  "all visible layers? (otherwise just the current layer is used.)" TRUE
)

;
(script-fu-menu-register "script-fu-gridslice"
			 "<Image>/misch")
;			 "<Image>/Image/Guides")			 

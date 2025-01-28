/**
 * File              : ChatBox.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 26.01.2025
 * Last Modified Date: 26.01.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
/**
 * ChatBox.h
 * Copyright (c) 2025 Igor V. Sementsov <ig.kuzm@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <UIKit/UIKit.h>

@interface ChatBox : UIView 
<UITextViewDelegate>
{
}

@property (nonatomic, retain) UITextView *textView;

@end

// vim:ft=objc

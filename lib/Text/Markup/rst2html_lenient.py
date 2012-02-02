#!/usr/bin/env python
"""
Parse a reST file into HTML in a very forgiving way.

The script is meant to render specialized reST documents, such as Sphinx
files, preserving the content, while not emulating the original rendering.

The script is currently tested against docutils 0.7. Other version may break
it as it deals with the parser at a relatively low level.
"""

from docutils import nodes, utils
from docutils.core import publish_cmdline, default_description
from docutils.parsers.rst import Directive, directives, roles
from docutils.writers.html4css1 import HTMLTranslator, Writer
from docutils.parsers.rst.states import Body, Inliner


class any_directive(nodes.General, nodes.FixedTextElement):
    """A generic directive to deal with any unknown directive we may find."""
    pass

class AnyDirective(Directive):
    """A directive returning its unaltered body."""
    optional_arguments = 100 # should suffice
    has_content = True

    def run(self):
        children = []
        children.append(nodes.strong(self.name, u"%s: " % self.name))
        # keep the arguments, drop the options
        for a in self.arguments:
            if a.startswith(':') and a.endswith(':'):
                break
            children.append(nodes.emphasis(a, u"%s " % a))
        content = u'\n'.join(self.content)
        children.append(nodes.literal_block(content, content))
        node = any_directive(self.block_text, '', *children, dir_name=self.name)
        return [node]


class any_role(nodes.Inline, nodes.TextElement):
    """A generic role to deal with any unknown role we may find."""
    pass

class AnyRole:
    """A role to be rendered as a generic element with a specific class."""
    def __init__(self, role_name):
        self.role_name = role_name

    def __call__(self, role, rawtext, text, lineno, inliner,
                 options={}, content=[]):
        roles.set_classes(options)
        options['role_name'] = self.role_name
        node = any_role(rawtext, utils.unescape(text), **options)
        return [node], []


def catchall_directive(self, match, **option_presets):
    """Directive dispatch method.

    Replacement for Body.directive(): if a directive is not known, build one
    on the fly instead of reporting an error.
    """
    type_name = match.group(1)
    directive_class, messages = directives.directive(
        type_name, self.memo.language, self.document)

    # in case it's missing, register a generic directive
    if not directive_class:
        directives.register_directive(type_name, AnyDirective)
        directive_class, messages = directives.directive(
            type_name, self.memo.language, self.document)
        assert directive_class, "can't find just defined directive"

    self.parent += messages
    return self.run_directive(
        directive_class, match, type_name, option_presets)


def catchall_interpreted(self, rawsource, text, role, lineno):
    """Interpreted text role dispatch method.

    Replacement for Inliner.interpreted(): if a role is not known, build one
    on the fly instead of reporting an error.
    """
    role_fn, messages = roles.role(role, self.language, lineno,
                                   self.reporter)
    # in case it's missing, register a generic role
    if not role_fn:
        role_obj = AnyRole(role)
        roles.register_canonical_role(role, role_obj)
        role_fn, messages = roles.role(
            role, self.language, lineno, self.reporter)
        assert role_fn, "can't find just defined role"

    nodes, messages2 = role_fn(role, rawsource, text, lineno, self)
    return nodes, messages + messages2


def patch_docutils():
    """Change the docutils parser behaviour."""
    # Patch the constructs dispatch table
    for i, (f, p) in enumerate(Body.explicit.constructs):
        if f is Body.directive.im_func is f:
            Body.explicit.constructs[i] = (catchall_directive, p)
            break
    else:
        assert False, "can't find directive dispatch entry"

    # Patch the parser so that when an unknown directive is found, a generic one
    # is generated on the fly.
    Body.directive = catchall_directive

    # Patch the parser so that when an unknown interpreted text role is found,
    # a generic one is generated on the fly.
    Inliner.interpreted = catchall_interpreted


class MyTranslator(HTMLTranslator):
    """An HTML translator that can render with any_role/any_directive.
    """
    def visit_any_directive(self, node):
        cls = node.get('dir_name')
        cls = cls and 'directive-%s' % cls or 'directive'
        self.body.append(self.starttag(node, 'div', CLASS=cls))

    def depart_any_directive(self, node):
        self.body.append('\n</div>\n')

    def visit_any_role(self, node):
        cls = node.get('role_name')
        cls = cls and 'role-%s' % cls or 'role'
        self.body.append(self.starttag(node, 'span', '', CLASS=cls))

    def depart_any_role(self, node):
        self.body.append('</span>')


def main():
    # Make docutils lenient.
    patch_docutils()

    # Create a writer to deal with the generic element we may have created.
    writer = Writer()
    writer.translator_class = MyTranslator

    description = (
        'Generates (X)HTML documents from standalone reStructuredText '
       'sources.  Be extremely forgiving against unknown elements.  '
       + default_description)

    publish_cmdline(writer=writer, description=description)


if __name__ == '__main__':
    main()

